extends Node3D
class_name Builder

@export var mouse_sens : float = 0.01
@export var blocks : Array[PackedScene]
@export var scroll_sens : float = 0.4
@export var player : Player
@export var part_limits : Array[float]
@export var power_used : Array[int]

@onready var vehicle: VehicleBody3D = $Vehicle
@onready var camera_arm: Node3D = $"Camera Arm"
@onready var cam: Camera3D = $"Camera Arm/Cam"
@onready var preview: MeshInstance3D = $Preview
@onready var current_parent : Node3D = $Vehicle

var current_block_index : int = 0
var arr : Array[Node3D]
var part_id : int = 0
var group_id : int = 0

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

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("complete"):
		for i in range(part_limits.size()):
			part_limits[i] += 1000
	$UI.visible = player.building
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
			check_nearby_nodes(delete)
		if Input.is_action_just_pressed("set parent"):
			check_nearby_nodes(set_parent)
		var y = int(Input.is_action_just_pressed("rotate +y")) - int(Input.is_action_just_pressed("rotate -y"))
		var x = int(Input.is_action_just_pressed("rotate +x")) - int(Input.is_action_just_pressed("rotate -x"))
		var z = int(Input.is_action_just_pressed("rotate +z")) - int(Input.is_action_just_pressed("rotate -z"))
		check_nearby_nodes(rotate_node,[x,y,z])
		if Input.is_action_just_pressed("reset parent"):
			current_parent = $Vehicle
		if not current_parent:
			current_parent = $Vehicle
		var group_change_input : int = int(Input.is_action_just_pressed("change active group right")) - int(Input.is_action_just_pressed("change active group left"))
		group_id += group_change_input
		if group_id < 0:
			group_id = 0
		$"UI/HBoxContainer/Servo Group".text = "Current Servo Group: " + str(group_id)
		camera_arm.position = preview.position
		current_block_index = clamp(current_block_index,0,blocks.size() - 1)
		var tmp_part = blocks[current_block_index].instantiate()
		$UI/HBoxContainer/Block.text = "Part: " + tmp_part.name
		$UI/HBoxContainer/Parent.text = "Parent: " + current_parent.name
		var limit = part_limits[current_block_index]
		if limit == int(limit):
			limit = int(limit)
		$"UI/HBoxContainer/Parts Left".text = "Parts Left: " + str(limit)
		$"UI/HBoxContainer/Net Power".text = "Net Power: " + str(vehicle.total_power_used)
		if Input.is_action_just_pressed("build part"):
			if limit >= 1:
				part_id += 1
				var part = blocks[current_block_index].instantiate()
				part.position += preview.position
				part.position -= current_parent.global_position - position
				part.name = part.name + str(part_id)
				part.set_meta("index",current_block_index)
				current_parent.add_child(part)
				vehicle.total_power_used -= power_used[current_block_index]
				part_limits[current_block_index] -= 1
				if current_parent != $Vehicle:
					$Vehicle.parented_parts.append(part)
					var reparent_duplicate : Node3D = part.duplicate()
					for child in reparent_duplicate.get_children(true):
						if child:
							child.queue_free()
					reparent_duplicate.position = part.global_position - $Vehicle.global_position
					reparent_duplicate.name = reparent_duplicate.name + str(part_id) + " Duplicate"
					$Vehicle.add_child(reparent_duplicate)
					$Vehicle.reparented_parts.append(reparent_duplicate)
				if part is Servo:
					current_parent = part.rotation_point
					part.vehicle = vehicle
					part.group_id = group_id
				if current_block_index == 4:
					vehicle.seat = part

func rotate_node(node : Node3D,x : int, y : int, z : int):
	node.rotate_y(y * 1.5708)
	node.rotate_x(x * 1.5708)
	node.rotate_z(z * 1.5708)

func set_parent(node : Node3D):
	if node is Servo:
		current_parent = node.rotation_point

func delete(node : Node3D):
	for child in node.get_children(true):
		if child is Node3D:
			delete(child)
	if node.get_parent() != vehicle:
		vehicle.parented_parts.erase(node)
		vehicle.reparented_parts.erase(node)
	if node.has_meta("index"):
		var index = node.get_meta("index")
		part_limits[index] += 1
		vehicle.total_power_used += power_used[index]
	node.queue_free()

func test(node : Node3D):
	print(node.name)

func check_nearby_nodes(callback: Callable, extra_args: Array = []) -> void:
	var preview_pos: Vector3 = preview.global_position
	for child in vehicle.get_children():
		_process_node_recursive(child, preview_pos, callback, extra_args)

func _process_node_recursive(current_node: Node, preview_pos: Vector3, callback: Callable, extra_args: Array) -> void:
	if not "Duplicate" in current_node.name:
		if preview_pos.distance_squared_to(current_node.global_position) <= 0.25 and not current_node is SpringArm3D:
			var full_args: Array = [current_node]
			full_args.append_array(extra_args)
			callback.callv(full_args)
		if current_node is Servo:
			for child in current_node.rotation_point.get_children():
				_process_node_recursive(child, preview_pos, callback, extra_args)
