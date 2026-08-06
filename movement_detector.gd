extends CollisionShape3D

class_name Movment_Detecotor

@export var actions : Array[String] = ["space"]
@export var vehicle : VehicleBody3D
@export var player : Player
@export var velocity_threshold = 0

func _ready() -> void:
	set_meta("actions",1)

func _physics_process(_delta: float) -> void:
	if vehicle.total_power_used >= 0 and not player.building and player.driving:
		var relative_position: Vector3 = global_position - vehicle.global_position
		var global_point_velocity: Vector3 = vehicle.linear_velocity + vehicle.angular_velocity.cross(relative_position)
		var local_point_velocity: Vector3 = global_basis.inverse() * global_point_velocity
		var local_y_velocity: float = local_point_velocity.y
		if local_y_velocity > velocity_threshold:
			Input.action_press(actions[0])
		else:
			Input.action_release(actions[0])
