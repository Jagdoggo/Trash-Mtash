extends CollisionShape3D

@export var distance : float = 4
@export var actions : Array[String] = ["space"]

@onready var ray_cast_3d: RayCast3D = $RayCast3D

func _ready() -> void:
	set_meta("actions",1)
	ray_cast_3d.target_position.y = -distance

func _physics_process(_delta: float) -> void:
	if ray_cast_3d.is_colliding():
		if not Input.is_action_pressed(actions[0]):
			Input.action_press(actions[0])
	else:
		if Input.is_action_pressed(actions[0]):
			Input.action_release(actions[0])
