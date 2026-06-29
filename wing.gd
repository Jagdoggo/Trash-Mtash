extends CollisionShape3D
class_name Wing

@export var lift_factor = -0.005
@export var wing_area = 2.0
@export var vehicle : VehicleBody3D

var air_density: float = 1.2

func _physics_process(_delta: float) -> void:
	if not vehicle or vehicle.freeze:
		return
	
	var block_world_pos = global_position
	var global_offset = block_world_pos - vehicle.global_position
	
	# 1. Calculate true 3D point velocity in world space (Don't flatten Y!)
	var v_world = vehicle.linear_velocity + vehicle.angular_velocity.cross(global_offset)
	var speed = v_world.length()
	
	if speed < 0.1:
		return
		
	# 2. Convert velocity into the wing's LOCAL space
	# This reveals how the wind hits the wing after servo rotations
	var v_local = global_basis.inverse() * v_world
	
	# 3. Calculate Angle of Attack (AoA) based on local wind directions
	# Godot Local: -Z is forward, +Y is upward
	var aoa = atan2(v_local.y, -v_local.z)
	
	# 4. Standard arcade lift coefficient based on the rotation angle
	var cl = sin(2.0 * aoa)
	
	# 5. Calculate the Lift Magnitude using your formulas
	var clamped_speed = clamp(speed, 0.0, 100.0)
	var lift_magnitude = 0.5 * lift_factor * wing_area * air_density * pow(clamped_speed, 2) * cl
	
	# 6. Generate the lift force locally (it acts along the wing's local Y-axis)
	var local_force = Vector3(0, lift_magnitude, 0)
	
	# 7. Convert the force back to WORLD space so vehicle.apply_force can use it
	var world_force = global_basis * local_force
	
	# 8. Apply force using your verified global offset configuration
	print(local_force)
	vehicle.apply_force(world_force, global_offset)
