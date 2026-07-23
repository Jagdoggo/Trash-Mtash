extends CollisionShape3D
class_name Gyro_stabilizer

@export var vehicle : VehicleBody3D
@export var player : Player

func _process(delta: float) -> void:
	if vehicle.total_power_used >= 0 and not player.building and player.driving:
		vehicle.rotation.x = 0
		vehicle.rotation.z = 0
