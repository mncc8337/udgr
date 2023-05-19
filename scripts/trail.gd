extends MeshInstance3D

@onready var MAIN = get_tree().get_root().get_node("main/")

var startpoint: Vector3
var endpoint: Vector3
var length: float
var original: Vector3
var process_start = false

func start(time):
	var vec = endpoint - startpoint
	if vec.x > 0:
		rotation.z = PI
	var angle = atan(vec.y/vec.x)
	if vec.y < 0:
		angle = PI + angle
		rotation.z += PI
	length = sqrt(pow(vec.x, 2) + pow(vec.y, 2))
	scale.x = length
	vec = (startpoint + endpoint)/2
	position = vec
	rotation.z += angle
	process_start = true
	$Timer.wait_time = time
	$Timer.start()
	
func _process(delta):
	if $Timer.is_stopped() and process_start:
		position = lerp(position, endpoint, delta*5)
		scale.x = lerp(scale.x, 0.0, delta*5)
		if scale.x < 0.005:
			queue_free()
