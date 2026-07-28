extends CollisionShape3D
class_name Gyro_stabilizer

@export var vehicle : VehicleBody3D
@export var player : Player
@export var stiffness: float = 5000.0
@export var damping: float = 500.0

func _physics_process(delta: float) -> void:
	if vehicle.total_power_used >= 0 and not player.building and player.driving:
		var local_x: Vector3 = global_transform.basis.x
		var current_up: Vector3 = global_transform.basis.y
		var target_up: Vector3 = Vector3.UP
		var tilt_axis: Vector3 = current_up.cross(target_up)
		var x_tilt_amount: float = tilt_axis.dot(local_x)
		var x_angular_vel: float = vehicle.angular_velocity.dot(local_x)
		var torque_magnitude: float = (x_tilt_amount * stiffness) - (x_angular_vel * damping)
		var corrective_torque: Vector3 = local_x * torque_magnitude
		vehicle.apply_torque(corrective_torque)
