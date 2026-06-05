extends CollisionShape3D
class_name Servo

@export var rotation_point : CharacterBody3D
@export var speed : float = 30

func _process(delta: float) -> void:
	rotation_point.position = Vector3.ZERO
	var input = Input.get_axis("servo back","servo forward")
	rotation_point.rotation_degrees.x += delta * speed * input
