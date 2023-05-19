extends Node

var mouse_pos = Vector2(1, 1)
var mouse_pos_in_world = Vector3(1, 1, 0) # controlled by camera
var mouse_moving = false
var window_size = Vector2(1152, 648)

var rng = RandomNumberGenerator.new()

func fit_info_panel():
	$UI/Panel.size = Vector2(window_size.x * 2/7, window_size.y * 1.25/15)
	$UI/Panel.position = Vector2(window_size.x, window_size.y) - $UI/Panel.size

	var gap = $UI/Panel.size.y/2 - $UI/Panel/gun_name.size.y/2

	$UI/Panel/gun_name.position.x = gap
	$UI/Panel/gun_name.position.y = gap
	
	$UI/Panel/ammo.position.x = $UI/Panel.size.x - gap - $UI/Panel/ammo.size.x
	$UI/Panel/ammo.position.y = gap

func _process(_delta):
	fit_info_panel()

func _input(event):
	mouse_moving = event is InputEventMouseMotion
	if event is InputEventMouseMotion:
		window_size = DisplayServer.window_get_size()
		mouse_pos = event.position
