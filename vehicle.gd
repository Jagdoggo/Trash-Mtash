extends VehicleBody3D

@export var mouse_sens : float = 0.01
@export var scroll_sens : float = 0.4
@export var player : Player
@export var drive_force : float = 100
@export var turn_force : float = 30
@export var parented_parts : Array[Node3D]
@export var reparented_parts : Array[Node3D]
@export var seat : Node3D
@export var group_id : int = 0

@onready var camera_arm: SpringArm3D = $"Camera Arm"
@onready var cam: Camera3D = $"Camera Arm/Cam"

var flipped : bool = false
var flipped_steer : bool = true
var total_power_used : int

func _input(event: InputEvent) -> void:
	if not freeze:
		if player.driving and not player.building:
			if not cam:
				cam = $"Camera Arm/Cam"
			if not camera_arm:
				camera_arm = $"Camera Arm"
			if event is InputEventMouseMotion:
				camera_arm.rotation.y += -event.relative.x * mouse_sens
				camera_arm.rotation.x += -event.relative.y * mouse_sens
				camera_arm.rotation_degrees.x = clamp(camera_arm.rotation_degrees.x,-90,90)
			if event is InputEventMouseButton and event.is_pressed():
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					camera_arm.spring_length -= event.factor * scroll_sens
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					camera_arm.spring_length += event.factor * scroll_sens
				camera_arm.spring_length = clamp(camera_arm.spring_length,1,15)

func  _process(_delta: float) -> void:
	#print(total_power_used)
	if player and player.driving and not player.building and not freeze:
		var group_change_input : int = int(Input.is_action_just_pressed("change active group right")) - int(Input.is_action_just_pressed("change active group left"))
		group_id += group_change_input
		if group_id < 0:
			group_id = 0
		
		reposition.call_deferred()
		
		if Input.is_action_just_pressed("switch drive dir"):
			if flipped:
				flipped = false
			else:
				flipped = true
		if Input.is_action_just_pressed("switch steer dir"):
			if flipped_steer:
				flipped_steer = false
			else:
				flipped_steer = true
		var drive : float = Input.get_axis("backward","forward") * drive_force
		var steer : float = Input.get_axis("left","right") * turn_force
		if flipped:
			drive *= -1
		if flipped_steer:
			steer *= -1
		engine_force = drive
		steering = deg_to_rad(steer)

func reposition():
	for i in range(parented_parts.size()):
		var original = parented_parts[i]
		var duplicate_node = reparented_parts[i]
		duplicate_node.transform = global_transform.affine_inverse() * original.global_transform
