extends RigidBody3D

var collide_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.wait_time = 5
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()
	body_entered.connect(_collided)

func _on_timer_timeout():
	queue_free()
	
func _collided(body):
	collide_count += 1
	if collide_count == 2:
		queue_free()
