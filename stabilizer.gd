extends CollisionShape3D
class_name Stabilizer

@export var vehicle : VehicleBody3D
@export var yaw_damping := -5000.0

func _physics_process(_delta):
	if !vehicle:
		return
	var yaw_rate = vehicle.angular_velocity.dot(vehicle.global_basis.y)
	print(yaw_rate * yaw_damping * Vector3.UP)
	vehicle.apply_torque(yaw_rate * yaw_damping * Vector3.UP * vehicle.global_basis.inverse())
