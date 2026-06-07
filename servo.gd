extends CollisionShape3D
class_name Servo

@export var rotation_point : Node3D
@export var speed : float = 30

func _process(delta: float) -> void:
	var input = float(Input.get_axis("servo back","servo forward"))
	if rotation_point:
		rotation_point.rotation_degrees.x += delta * speed * input
	else:
		if get_child_count() > 0:
			rotation_point = get_node("Rotation Point")
