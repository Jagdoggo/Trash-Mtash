extends CollisionShape3D
class_name Stabilizer

@export var vehicle : VehicleBody3D
@export var yaw_damping := -7500.0

@export var lateral_drag_factor := -8.0 

func _physics_process(_delta):
	if !vehicle:
		return
	var block_world_pos = global_position
	var global_offset = block_world_pos - vehicle.global_position
	var yaw_rate = vehicle.angular_velocity.dot(vehicle.global_basis.y)
	vehicle.apply_torque(yaw_rate * yaw_damping * vehicle.global_basis.y)
	var v_world = vehicle.linear_velocity + vehicle.angular_velocity.cross(global_offset)
	var lateral_speed = v_world.dot(vehicle.global_basis.x)
	var local_side_force = Vector3(lateral_speed * lateral_drag_factor, 0, 0)
	var world_side_force = vehicle.global_basis * local_side_force
	vehicle.apply_force(world_side_force, global_offset)
