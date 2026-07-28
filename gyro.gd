extends CollisionShape3D
class_name Gyro

@export var vehicle : VehicleBody3D
@export var player : Player
@export var strength : float = 1000
@export var negative_action : String
@export var positive_action : String

func _process(delta: float) -> void:
	if vehicle.total_power_used >= 0 and not player.building and player.driving:
		var input_axis = Input.get_axis(negative_action, positive_action)
		if input_axis != 0:
			var local_x = global_transform.basis.z
			var torque_vector = local_x * input_axis * strength
			vehicle.apply_torque(torque_vector)
