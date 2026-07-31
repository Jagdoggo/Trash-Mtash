extends CollisionShape3D
class_name Propeller

@export var vehicle : VehicleBody3D
@export var player : Player
@export var actions : Array[String] = ["space"]

func _ready() -> void:
	set_meta("actions",1)

func _process(delta: float) -> void:
	if Input.is_action_pressed(actions[0]) and vehicle.total_power_used >= 0 and vehicle.get_parent():
		var forward_direction: Vector3 = -global_transform.basis.z
		var thrust_force: Vector3 = forward_direction * 1000
		var force_position: Vector3 = global_position - vehicle.global_position
		vehicle.apply_force(thrust_force,force_position)
