extends CollisionShape3D
class_name Propeller

@export var vehicle : VehicleBody3D

func _process(delta: float) -> void:
	if Input.is_action_pressed("activate propeller") and vehicle.total_power_used >= 0:
		print("fly")
		# 1. Calculate the propeller's LOCAL forward direction in the 3D world
		# In Godot, -global_transform.basis.z points directly out the front of the object
		var forward_direction: Vector3 = -global_transform.basis.z
		
		# 2. Scale the thrust force
		var thrust_force: Vector3 = forward_direction * 1000
		
		# 3. Calculate the relative position offset from the vehicle's center
		var force_position: Vector3 = global_position - vehicle.global_position
		
		# 4. Apply the directional force to the vehicle body
		vehicle.apply_force(thrust_force,force_position                  )
