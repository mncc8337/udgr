extends RigidBody3D

@onready var MAIN = get_tree().get_root().get_node("main")
@onready var players = get_tree().get_nodes_in_group("player")

@export var preview_img: Texture

signal hit_received(damage)
signal destructive_mode
var health = 100
var is_holding = false
var destructive = false
var is_destroyed = false

func _ready():
	$Timer.timeout.connect(_on_time_out)
	hit_received.connect(on_hit_received)
	body_entered.connect(on_body_entered)
	destructive_mode.connect(on_destructive_mode)

func toggle_holding(hold):
	if hold:
		linear_velocity = Vector3.ZERO
		collision_layer = 0
		collision_mask = 0
		is_holding = true
		freeze = true
	else:
		collision_layer = 1
		collision_mask = 1
		is_holding = false
		freeze = false

func _physics_process(_delta):
	position.z = 0
	linear_velocity.z = 0
	sleeping = is_holding
	if not is_holding:
		for player in players:
			var squared_pick_range = pow(player.pick_range, 2)
			if self.global_position.distance_squared_to(player.global_position) <= squared_pick_range:
				if not player.pickables.has(self):
					player.pickables.append(self)
			else:
				player.pickables.erase(self)

func on_destructive_mode():
	destructive = true

func on_body_entered(body):
	var damage = linear_velocity.length() * 1.5
	if destructive:
		damage *= 2
	if body.is_in_group("box"):
		damage += body.linear_velocity.length() * 1.5
		body.hit_received.emit(damage)
	if body.is_in_group("gun"):
		damage += body.linear_velocity.length()
	damage = round(damage)
	if destructive:
		damage = 100
	hit_received.emit(damage)

func disable_collider():
	$collider.disabled = true

func on_hit_received(damage):
	if is_destroyed:
		return
	health -= damage
	if health <= 0:
		is_destroyed = true
		sleeping = true
		call_deferred("disable_collider")
		if $collider != null:
			$collider.queue_free()
		$mesh.visible = false
		$GPUParticles3D.emitting = true
		$Timer.wait_time = 0.5
		$Timer.start()

func _on_time_out():
	queue_free()
