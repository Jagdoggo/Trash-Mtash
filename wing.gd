extends CollisionShape3D
class_name Wing

@export var lift_factor: float = 0.15
@export var wing_area: float = 2.0
@export var vehicle : VehicleBody3D

# Forces the structural damping to scale smoothly with your custom Godot body damping
@export var structural_damping: float = 0

var air_density: float = 1.2

func _physics_process(_delta: float) -> void:
	if not vehicle or vehicle.freeze:
		return
	
	var block_world_pos = global_position
	var global_offset = block_world_pos - vehicle.global_position
	
	# 1. Calculate true 3D point velocity in world space
	var v_world = vehicle.linear_velocity + vehicle.angular_velocity.cross(global_offset)
	var speed = v_world.length()
	
	if speed < 1.0:
		return
		
	# 2. Convert velocity into the wing's LOCAL space
	var v_local = global_basis.inverse() * v_world
	
	# 3. Detect block orientation relative to the vehicle
	var vehicle_up = vehicle.global_transform.basis.y
	var wing_up = global_transform.basis.y
	var flatness_alignment = abs(wing_up.dot(vehicle_up))
	
	if flatness_alignment < 0.1:
		return

	# ====================================================================
	# ARCADE MECHANIC 1: PADDLE DAMPING (Anti-Tumble)
	# ====================================================================
	var damping_force_y = -v_local.y * speed * structural_damping * wing_area
	
	# ====================================================================
	# ARCADE MECHANIC 2: DEFLECTION LIFT (Servo Support)
	# ====================================================================
	var vehicle_fwd = -vehicle.global_transform.basis.z
	var wing_fwd = -global_transform.basis.z
	var deflection = wing_fwd.dot(vehicle_up)
	
	var forward_speed = max(-v_local.z, 0.0)
	var deflection_lift_y = deflection * forward_speed * speed * lift_factor * wing_area

	# ====================================================================
	# ARCADE MECHANIC 3: MASS-SCALED CEILING
	# Instead of a hardcoded number, we cap the lift relative to the vehicle's mass.
	# This ensures a single wing can never single-handedly flip the entire vehicle.
	# ====================================================================
	var total_local_lift = damping_force_y + deflection_lift_y
	
	# Maximum lift per wing is capped at half the vehicle's gravity weight force
	var mass_lift_ceiling = (vehicle.mass * 9.8) * 0.5
	total_local_lift = clamp(total_local_lift, -mass_lift_ceiling, mass_lift_ceiling)

	# ====================================================================
	# 4. APPLY FORCES
	# ====================================================================
	var local_force = Vector3(0, total_local_lift, 0)
	var world_force = global_transform.basis * local_force
	
	vehicle.apply_force(world_force, global_offset)
