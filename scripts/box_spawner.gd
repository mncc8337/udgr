extends Node3D

@onready var MAIN = get_tree().get_root().get_node("main")
@onready var box = preload("res://scenes/box.tscn")

func _ready():
	$timer.timeout.connect(_on_time_out)

func _on_time_out():
	spawn()

func spawn():
	var b = box.instantiate()
	MAIN.add_child(b)
	var pos = Vector3(MAIN.rng.randf_range(-3, 3), 0, 0)
	b.position = position + pos
