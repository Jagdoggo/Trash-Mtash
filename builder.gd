extends Node3D
class_name Builder

@export var mouse_sens : float = 0.01
@export var blocks : Array[PackedScene]
@export var scroll_sens : float = 0.4
@export var player : Player

@onready var vehicle: VehicleBody3D = $Vehicle
@onready var camera_arm: Node3D = $"Camera Arm"
@onready var cam: Camera3D = $"Camera Arm/Cam"
@onready var preview: MeshInstance3D = $Preview
@onready var current_parent : Node3D = $Vehicle

var current_block_index : int = 0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if player.building:
		if event is InputEventMouseMotion:
			camera_arm.rotation.y += -event.relative.x * mouse_sens
			camera_arm.rotation.x += -event.relative.y * mouse_sens
			camera_arm.rotation_degrees.x = clamp(camera_arm.rotation_degrees.x,-90,90)
		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				cam.position.z -= event.factor * scroll_sens
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				cam.position.z += event.factor * scroll_sens
			cam.position.z = clamp(cam.position.z,1,15)

func _process(delta: float) -> void:
	if player.building:
		var inpupt_dir : Vector2 = Vector2(int(Input.is_action_just_pressed("right")) - int(Input.is_action_just_pressed("left")),int(Input.is_action_just_pressed("backward")) - int(Input.is_action_just_pressed("forward")))
		inpupt_dir = inpupt_dir.rotated(deg_to_rad(-round(camera_arm.rotation_degrees.y/90)*90))
		preview.position += Vector3(inpupt_dir.x,0,inpupt_dir.y)
		if Input.is_action_just_pressed("move down"):
			preview.position.y -= 1
		if Input.is_action_just_pressed("move up"):
			preview.position.y += 1
		if Input.is_action_just_pressed("cycle block left"):
			current_block_index -= 1
		if Input.is_action_just_pressed("cycle block right"):
			current_block_index += 1
		if Input.is_action_just_pressed("delete part"):
			for child in vehicle.get_children():
				if preview.position.distance_squared_to(child.position) < 0.25 and child is not MeshInstance3D:
					child.queue_free()
		if Input.is_action_just_pressed("set parent"):
			for child in vehicle.get_children():
				if preview.position.distance_squared_to(child.position) < 0.25 and child is Servo:
					current_parent = child.rotation_point
		if Input.is_action_just_pressed("reset parent"):
			current_parent = $Vehicle
		camera_arm.position = preview.position
		current_block_index = clamp(current_block_index,0,blocks.size() - 1)
		if Input.is_action_just_pressed("build part"):
			var part = blocks[current_block_index].instantiate()
			part.position = preview.position
			current_parent.add_child(part)
