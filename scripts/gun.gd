extends RigidBody3D

@onready var MAIN = get_tree().get_root().get_node("main")
@onready var ammo_text = get_tree().get_root().get_node("main/UI/Panel/ammo")
@onready var players = get_tree().get_nodes_in_group("player")
@onready var trail = preload("res://scenes/trail.tscn")

@export var gun_name: String
@export var damage = 41.0
@export var max_recoil = .1 # time PI/2
@export var inaccuracy = 0.01
@export var firing_speed = .1
@export var bullet_per_shot = 1
@export var magazine_size = 40
@export var view_range_increase_to = 6.5
@export var speed_when_holding = 1.0 # * 100 %
@export var audio_stream: AudioStream
@export var between_firing_animation = "no"

var is_holding = false
var magazine: int
var reloading_animation = false

func _ready():
	magazine = magazine_size
	$Timer.wait_time = firing_speed
	$flash_timer.wait_time = .05
	$flash_timer.timeout.connect(_on_flash_timer_timeout)
	$AnimationPlayer.animation_finished.connect(_on_finish_reloaded)

func _on_flash_timer_timeout():
	$flash.visible = false
	
func _on_finish_reloaded(anim_name):
	if is_holding and reloading_animation:
		magazine = magazine_size
		$AnimationPlayer.stop()
		# player
		get_parent().get_parent().is_reloading = false
		ammo_text.text = str(magazine) + '/' + str(magazine_size)
	reloading_animation = false

func reload():
	if is_holding:
		$AnimationPlayer.speed_scale = 1
		if magazine > 0:
			$AnimationPlayer.speed_scale = 1.5
		$AnimationPlayer.play("reloading")
		reloading_animation = true
		# player
		get_parent().get_parent().is_reloading = true

func toggle_holding(hold):
	if hold:
		linear_velocity = Vector3.ZERO
		collision_layer = 0
		collision_mask = 0
		is_holding = true
		freeze = true
		if magazine == 0:
			reload()
	else:
		collision_layer = 1
		collision_mask = 1
		is_holding = false
		freeze = false

func play_firing_sound():
	if audio_stream == null: return
	
	var audioStreamPlayer = AudioStreamPlayer3D.new();
	MAIN.add_child(audioStreamPlayer)
	audioStreamPlayer.stream = audio_stream
	audioStreamPlayer.global_position = $firing_sound_pos.global_position
	audioStreamPlayer.pitch_scale = MAIN.rng.randf_range(0.8, 1.2)
	audioStreamPlayer.volume_db = .8
	
	audioStreamPlayer.finished.connect(audioStreamPlayer.queue_free)
	audioStreamPlayer.play()

func shot_bullet():
	var angle = MAIN.rng.randf_range(-inaccuracy, inaccuracy)
	$raycast.rotation.z = angle # this make bullet inaccurate
	$raycast.force_raycast_update()

	var point = $raycast.get_collision_point()
	if not $raycast.is_colliding():
		var dir = ($raycast.global_position - $start.global_position) * 400
		point.x = $raycast.global_position.x + dir.x
		point.y = $raycast.global_position.y + dir.y

	var obj = $raycast.get_collider()
	if obj != null:
		if obj.is_in_group("box"):
			obj.hit_received.emit(damage)

	var new_trail = trail.instantiate()
	MAIN.add_child(new_trail)
	new_trail.startpoint = $raycast.global_position
	new_trail.endpoint = point
	new_trail.start(0.2)
	
	$raycast.rotation.z = 0

func _physics_process(_delta):
	position.z = 0
	linear_velocity.z = 0
	if not is_holding:
		for player in players:
			var squared_pick_range = pow(player.pick_range, 2)
			if self.global_position.distance_squared_to(player.global_position) <= squared_pick_range:
				if not player.pickables.has(self):
					player.pickables.append(self)
			else:
				player.pickables.erase(self)
	
func _process(delta):
	if $AnimationPlayer.is_playing() and $AnimationPlayer.current_animation == "reloading":
		var time_left = $AnimationPlayer.current_animation_length - $AnimationPlayer.current_animation_position
		ammo_text.text = str(round(time_left*100/$AnimationPlayer.speed_scale)/100)+'s'
	
	if Input.is_action_just_pressed("reload") and is_holding and magazine != magazine_size:
		reload()
		
	var reloading_stopped = not $AnimationPlayer.is_playing()
	if Input.is_action_just_pressed("fire") and not reloading_stopped and magazine > 0:
		$AnimationPlayer.stop()
		get_parent().get_parent().is_reloading = false
		
		reloading_stopped = true
	if (Input.is_action_pressed("fire")
			and $Timer.is_stopped()
			and is_holding
			and reloading_stopped):
		
		for i in bullet_per_shot:
			shot_bullet()

		$flash.visible = true
		$flash_timer.start()
		play_firing_sound()

		var recoil = MAIN.rng.randf_range(max_recoil * PI/2 * 0.5, max_recoil * PI/2)
		rotation.z += recoil
		rotation.z = min(rotation.z, PI/2)
		
		magazine -= 1
		if magazine == 0:
			reload()
		else:
			ammo_text.text = str(magazine) + "/" + str(magazine_size)
			$Timer.start()
			if between_firing_animation != "no":
				$AnimationPlayer.play(between_firing_animation)
			
	if is_holding:
		var min_length = ($raycast.global_position - get_parent().global_position).length()
		var d = max((MAIN.mouse_pos_in_world - get_parent().get_parent().position).length(), min_length)
		var zi = get_parent().position.z
		if not $AnimationPlayer.is_playing():
			rotation.y = -abs(atan(d/zi)) + PI/2
			rotation.z = lerp(rotation.z, 0.0, delta*5)
		else:
			rotation.y = 0
			rotation.z = 0
