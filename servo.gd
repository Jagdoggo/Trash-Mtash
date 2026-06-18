extends CollisionShape3D
class_name Servo

@export var rotation_point : Node3D
@export var speed : float = 20
@export var group_id : int

var vehicle : VehicleBody3D
var builder : CharacterBody3D

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
	if vehicle.group_id == group_id and vehicle.total_power_used >= 0 and builder.player.driving:
		var input = float(Input.get_axis("servo back","servo forward"))
		if rotation_point:
			rotation_point.rotation_degrees.x += delta * speed * input
		else:
			if get_child_count() > 0:
				rotation_point = get_node("Rotation Point")
