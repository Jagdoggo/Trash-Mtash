extends CollisionShape3D

@export var actions : Array[String] = ["4","5","6"]
@export var frames : int = 25

var frame : int = 0

func _ready() -> void:
	set_meta("actions",3)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame >= frames:
		frame = 1
		if Input.is_action_pressed(actions[0]) and Input.is_action_pressed(actions[1]):
			Input.action_press(actions[2])
		else:
			Input.action_release(actions[2])
