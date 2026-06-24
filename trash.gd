extends RigidBody3D
class_name Trash

@export var recycle_info : TrashRecycle
@export var protected_from_despawn : bool = false

var player_node : Player

func _ready() -> void:
	connect("body_entered",collided)
	if freeze:
		protected_from_despawn = true

func _process(delta: float) -> void:
	var distance = abs(player_node.position.x - position.x) + abs(player_node.position.z - position.z)
	freeze = distance > 15

func collided(body : Node) -> void:
	if body is VehicleBody3D:
		protected_from_despawn = true
