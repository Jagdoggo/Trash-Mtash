extends CollisionShape3D
class_name Magnet

var active : bool = true
var is_picking_up : bool = false

func _process(delta: float) -> void:
	if "Duplicate" in name:
		return
	if Input.is_action_just_pressed("toggle magnet"):
		if active:
			active = false
			is_picking_up = false
			for body in $Pickup.get_overlapping_bodies():
				if body is RigidBody3D and body is not VehicleBody3D:
					body.freeze = false
		else:
			active = true
	if active:
		for body in $Pickup.get_overlapping_bodies():
			if body is RigidBody3D and body is not VehicleBody3D and body.freeze: 
				body.position = $Pickup.global_position
				body.rotation = $Pickup.global_rotation

func _on_pickup_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body is not VehicleBody3D and active and not is_picking_up:
		is_picking_up = true
		body.freeze = true

func _on_pickup_body_exited(body: Node3D) -> void:
	if body is RigidBody3D and body is not VehicleBody3D and active:
		body.freeze = false
