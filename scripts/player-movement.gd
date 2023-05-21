extends CharacterBody3D

@onready var MAIN = get_tree().get_root().get_node("main")

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 5.2
@export var gun_focus_speed = 8.0
@export var pick_range = 2.5

@onready var z = position.z

var current_max_speed = SPEED;

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var pickables = []
var holding: Node3D
var is_reloading = false

func update_info_panel(gun_name, ammo):
	var panel = MAIN.get_node("UI/Panel")
	var label = panel.get_node("gun_name")
	var ammo_text = panel.get_node("ammo")
	
	label.text = gun_name
	ammo_text.text = ammo
	
	panel.visible = gun_name != ""

func pick_gun():
	if holding != null:
		holding.position = holding.global_position
		holding.rotation = holding.global_rotation
		holding.toggle_holding(false)
		var angle
		if holding.is_in_group("gun"):
			angle = holding.rotation.z
			if rotation.y < -PI/2:
				angle = PI - angle
			$gun_holder.remove_child(holding)
			MAIN.add_child(holding)
			holding.get_node("AnimationPlayer").stop()
			is_reloading = false
		elif holding.is_in_group("box"):
			angle = $box_holder.rotation.z
			if rotation.y < -PI/2:
				angle = PI - angle
			$box_holder.remove_child(holding)
			MAIN.add_child(holding)
			holding.destructive_mode.emit()
		holding.apply_force(Vector3(cos(angle), sin(angle), 0) * 1500)
		holding = null
		current_max_speed = SPEED
		update_info_panel("", "")
	elif not pickables.is_empty():
		# remove any null in the begin of pickables
		while pickables[0] == null:
			pickables.remove_at(0)
		holding = pickables[0]
		MAIN.remove_child(holding)
		if holding.is_in_group("gun"):
			$gun_holder.add_child(holding)
			holding.position = Vector3.ZERO
			holding.rotation = Vector3.ZERO
			update_info_panel(holding.gun_name,
							str(holding.magazine) + '/' + str(holding.magazine_size))
		elif holding.is_in_group("box"):
			$box_holder.add_child(holding)
			holding.position = $box_holder/real_pos.position
			update_info_panel("box", "1/1")
		holding.toggle_holding(true)
		pickables.remove_at(0)
		
		current_max_speed = SPEED * holding.speed_when_holding

func _physics_process(delta):
	if Input.is_action_just_pressed("pickup"):
		pick_gun()
		
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var temp
	if $gun_holder.get_children().is_empty():
		temp = MAIN.mouse_pos_in_world - $gun_holder.global_position
	else:
		temp = MAIN.mouse_pos_in_world - $gun_holder.get_children()[0].get_node("start").global_position
	var angle = atan(temp.y / abs(temp.x))
	if not is_reloading:
		$gun_holder.rotation.z = lerp($gun_holder.rotation.z, angle, delta * gun_focus_speed)
	else:
		$gun_holder.rotation.z = 0
	
	temp = MAIN.mouse_pos_in_world - $box_holder.global_position
	angle = atan(temp.y / abs(temp.x))
	$box_holder.rotation.z = lerp($box_holder.rotation.z, angle, delta * 2.5)

	var go_left  = int(Input.is_action_pressed("left"))
	var go_right = int(Input.is_action_pressed("right"))
	var new_speed = current_max_speed * (go_right - go_left)
	if new_speed != 0: # if object gain speed
		velocity.x = lerp(velocity.x, new_speed, delta*5)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 5)
	if move_and_slide(): # true if collided
		for col_idx in get_slide_collision_count():
			var col = get_slide_collision(col_idx)
			if col.get_collider() is RigidBody3D:
				col.get_collider().apply_central_impulse(-col.get_normal() * 0.3)
				col.get_collider().apply_impulse(-col.get_normal() * 0.01, col.get_position())
	position.z = z # lock z
