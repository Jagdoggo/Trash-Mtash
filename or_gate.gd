extends CollisionShape3D

class_name O_Gate

@export var actions : Array[String] = ["4","5","6"]
@export var frames : int = 25
@export var vehicle : VehicleBody3D
@export var player : Player

var frame : int = 0

func _ready() -> void:
	set_meta("actions",3)

func _physics_process(_delta: float) -> void:
	if vehicle.total_power_used >= 0 and not player.building and player.driving:
		frame += 1
		if frame >= frames:
			frame = 1
			if Input.is_action_pressed(actions[0]) or Input.is_action_pressed(actions[1]):
				Input.action_press(actions[2])
			else:
				Input.action_release(actions[2])
