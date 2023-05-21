extends Camera3D

@onready var MAIN = get_tree().get_root().get_node("main")

@export var target: Node3D
@export var follow_speed = 5
@export var turn_speed = 10

var mouse_vec: Vector2
var mouse_pos: Vector3 # mouse position in world

func _physics_process(delta):
	# get mouse position in 3D space
	var window = MAIN.window_size
	mouse_vec = MAIN.mouse_pos - Vector2(window.x/2, window.y/2)
	mouse_pos = Vector3(mouse_vec.x, -mouse_vec.y, 0) * size/window.x
	mouse_pos.y += position.z * tan(rotation.x)
	mouse_vec.y *= window.x / window.y
	mouse_vec *= .2
	
	MAIN.mouse_pos_in_world = mouse_pos + position
	MAIN.mouse_pos_in_world.z = 0
	
	# make camera follow player
	var t = delta * follow_speed
	position.x = lerp(position.x, target.position.x, t)
	position.y = lerp(position.y, target.position.y, t) + .05
	
	# if target is holding something then increase view range
	if target.holding != null:
		mouse_vec *= target.holding.view_range_increase_to
	position.x = lerp(position.x, position.x + mouse_vec.x, 0.05 * delta)
	position.y = lerp(position.y, position.y - mouse_vec.y, 0.05 * delta)
	
	var target_vec = mouse_pos - target.position + position
	
	if target_vec.x < 0:
		target.rotation.y = lerp(target.rotation.y, -PI, delta * turn_speed)
	else:
		target.rotation.y = lerp(target.rotation.y, 0.0, delta * turn_speed)
