extends RigidBody3D
class_name Trash

@export var trash_type_id : String = ""

func _ready() -> void:
	sleeping = true
