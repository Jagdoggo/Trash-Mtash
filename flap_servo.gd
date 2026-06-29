extends Servo
class_name Flap_Servo

@export var limit : float = 30

func _ready() -> void:
	speed = 200

func _process(delta: float) -> void:
	if not vehicle:
		var current_node = get_parent()
		var running = true
		while running:
			if current_node is VehicleBody3D:
				vehicle = current_node
				running = false
			else:
				current_node = current_node.get_parent()
	if not builder:
		if vehicle.get_parent().name == "Builder":
			builder = vehicle.get_parent()
	if vehicle.group_id == group_id and vehicle.total_power_used >= 0 and not builder:
		var input = float(Input.get_axis("servo back","servo forward"))
		if rotation_point:
			rotation_point.rotation_degrees.x += delta * speed * input
			rotation_point.rotation_degrees.x = clamp(rotation_point.rotation_degrees.x,-limit,limit)
			if input == 0:
				rotation_point.rotation_degrees.x = 0
		else:
			if get_child_count() > 0:
				rotation_point = get_node("Rotation Point")
