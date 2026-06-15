extends CollisionShape3D
class_name Magnet

var active : bool = true
var is_picking_up : bool = false

func _process(delta: float) -> void:
	if "Duplicate" in name:
		return
	if Input.is_action_just_pressed("toggle magnet"):
		if active:
			detatch()
		else:
			active = true
	if active:
		for body in $Pickup.get_overlapping_bodies():
			if body is RigidBody3D and body is not VehicleBody3D and body.freeze: 
				body.position = $Pickup.global_position
				body.rotation = $Pickup.global_rotation
				body.collision_mask = 2
				body.collision_layer = 2

func detatch():
	active = false
	is_picking_up = false
	for body in $Pickup.get_overlapping_bodies():
		if body is RigidBody3D and body is not VehicleBody3D:
			body.freeze = false
			body.collision_mask = 1
			body.collision_layer = 1

func _on_pickup_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and body is not VehicleBody3D and active and not is_picking_up:
		if body.has_method("collided"):
			body.protected_from_despawn = true
		is_picking_up = true
		body.freeze = true
		body.collision_mask = 2
		body.collision_layer = 2
