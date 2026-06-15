extends RigidBody3D
class_name Trash

@export var recycle_info : TrashRecycle
@export var protected_from_despawn : bool = false

func _ready() -> void:
	connect("body_entered",collided)
	if freeze:
		protected_from_despawn = true

func collided(body : Node) -> void:
	if body is VehicleBody3D:
		protected_from_despawn = true
