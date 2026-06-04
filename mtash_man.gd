extends CharacterBody3D
class_name Player

@export var SPEED = 5.0
@export var mouse_sens : float = 0.01
@export var jump_vel : float = 5
@export var scroll_sens : float = 0.4
@export var builder : Builder
@export var vehicle : VehicleBody3D

@onready var camera_arm: SpringArm3D = $"Camera Arm"
@onready var cam: Camera3D = $"Camera Arm/Cam"

var building = false
var driving = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if not building:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * mouse_sens)
			camera_arm.rotate_x(-event.relative.y * mouse_sens)
			camera_arm.rotation_degrees.x = clamp(camera_arm.rotation_degrees.x,-90,90)
		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera_arm.spring_length -= event.factor * scroll_sens
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera_arm.spring_length += event.factor * scroll_sens
			camera_arm.spring_length = clamp(camera_arm.spring_length,1,7.5)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("build"):
		if building:
			building = false
			builder.cam.current = false
			cam.current = true
			vehicle = builder.vehicle.duplicate()
			vehicle.player = self
			vehicle.position = Vector3(position.x,position.y + 2,position.z)
			vehicle.freeze = false
			get_parent().add_child(vehicle)
		else:
			building = true
			builder.cam.current = true
			cam.current = false
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if not building:
		if Input.is_action_just_pressed("drive"):
			if driving:
				driving = false
				cam.current = true
				vehicle.cam.current = false
			else:
				driving = true
				cam.current = false
				vehicle.cam.current = true
		if not driving:
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = jump_vel
			if not is_on_floor():
				velocity += get_gravity() * delta
			var input_dir := Input.get_vector("left", "right", "forward", "backward")
			var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
