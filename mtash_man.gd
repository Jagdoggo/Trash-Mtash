extends CharacterBody3D
class_name Player

@export var SPEED = 5.0
@export var mouse_sens : float = 0.01
@export var jump_vel : float = 5
@export var scroll_sens : float = 0.4
@export var builder : Builder
@export var vehicle : VehicleBody3D
@export var full_trash_scenes : Array[PackedScene]

@onready var camera_arm: SpringArm3D = $"Camera Arm"
@onready var cam: Camera3D = $"Camera Arm/Cam"
@onready var trash_detection_area: Area3D = $"Trash Detection Area"
@onready var educational: Control = $Educational

var building = false
var driving = false
var picked_up_trash : Trash = null
var trash_offset : Vector3
var vehicle_data : Array[Array]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Save.save_path != "":
		load_save.call_deferred()

func load_save():
	var file = FileAccess.open(Save.save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var save_data : Dictionary
			save_data = json.data
			position = Vector3(save_data["x"],save_data["y"],save_data["z"])
			builder.part_limits.assign(save_data["parts"])
			for i in range(save_data['ti'].size()):
				var new_trash = full_trash_scenes[save_data["ti"][i]].instantiate()
				new_trash.set_meta("t_index",save_data["ti"][i])
				new_trash.position = Vector3(save_data["tx"][i],save_data["ty"][i],save_data["tz"][i])
				new_trash.rotation = Vector3(save_data["trx"][i],save_data["try"][i],save_data["trz"][i])
				get_parent().add_child(new_trash)
			for i in range(save_data["is_clear"].size()):
				var progress_obj = get_parent().chunk_clear_progress.new()
				progress_obj.ammount_missing = save_data["missing_count"][i]
				if save_data["is_clear"][i]:
					var cleared_node : MeshInstance3D = get_parent().cleared_scene.instantiate()
					cleared_node.position = Vector3(save_data["chx"][i] * get_parent().chunk_size+get_parent().chunk_size/2,-1.9,save_data["chy"][i] * get_parent().chunk_size+get_parent().chunk_size/2)
					cleared_node.scale = Vector3(get_parent().chunk_size,1,get_parent().chunk_size)
					progress_obj.cleared_node = cleared_node
					get_parent().add_child(cleared_node)
				get_parent().all_chunk_clear_progress[Vector2i(save_data["chx"][i],save_data["chy"][i])] = progress_obj
			var parts : Dictionary[int,Node3D]
			for part in save_data["vehicle"]:
				var pid : int = part[1]
				var block = builder.blocks[part[0]].instantiate()
				builder.vehicle.total_power_used -= builder.power_used[part[0]]
				block.name = block.name + str(pid)
				block.position.x = part[2]
				block.position.y = part[3]
				block.position.z = part[4]
				block.rotation.x = part[5]
				block.rotation.y = part[6]
				block.rotation.z = part[7]
				parts[pid] = block
				block.set_meta("index",part[0])
				block.set_meta("pid",pid)
				block.set_meta("parent_pid",part[8])
				if part[0] == 4:
					builder.vehicle.seat = block
				if part[8]:
					parts[part[8]].rotation_point.add_child(block)
					builder.vehicle.parented_parts.append(block)
					var reparent_duplicate : Node3D = block.duplicate()
					for child in reparent_duplicate.get_children(true):
						if child:
							child.queue_free()
					reparent_duplicate.position = block.global_position - builder.vehicle.global_position
					reparent_duplicate.name = reparent_duplicate.name + str(pid) + " Duplicate"
					builder.vehicle.add_child(reparent_duplicate)
				else:
					builder.vehicle.add_child(block)
				
			print(save_data["vehicle"])
		else:
			print("JSON Parse Error: ", json.get_error_message())

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

func vehcicle_save_recurse(current_node : Node3D):
	if current_node.has_meta("index"):
		var data_arr : Array = []
		data_arr.append(current_node.get_meta("index"))
		data_arr.append(current_node.get_meta("pid"))
		data_arr.append(current_node.position.x)
		data_arr.append(current_node.position.y)
		data_arr.append(current_node.position.z)
		data_arr.append(current_node.rotation.x)
		data_arr.append(current_node.rotation.y)
		data_arr.append(current_node.rotation.z)
		data_arr.append(current_node.get_meta("parent_pid"))
		vehicle_data.append(data_arr)
		for child in current_node.get_children():
			vehcicle_save_recurse(child)

func save():
	var dir = FileAccess.open(Save.save_path, FileAccess.WRITE)
	if dir:
		var data = {"parts" : builder.part_limits,"x" : position.x,"y" : position.y,"z" : position.z}
		for child in builder.vehicle.get_children():
			vehcicle_save_recurse(child)
		var is_clear : Array[bool]
		var missing_count : Array[int]
		var chunkx : Array[int]
		var chunky : Array[int]
		for progress in get_parent().all_chunk_clear_progress.values():
			missing_count.append(progress.ammount_missing)
			var total_count = get_parent().piles_per_chunk * get_parent().trash_per_pile - progress.ammount_missing
			is_clear.append(total_count <= 0)
			chunkx.append(get_parent().all_chunk_clear_progress.find_key(progress).x)
			chunky.append(get_parent().all_chunk_clear_progress.find_key(progress).y)
		var trashids : Array[int]
		var trashxs : Array[float]
		var trashys : Array[float]
		var trashzs : Array[float]
		var trashroxs : Array[float]
		var trashroys : Array[float]
		var trashrozs : Array[float]
		for child in get_parent().get_children():
			if child is Trash:
				trashids.append(child.get_meta("t_index"))
				trashxs.append(child.position.x)
				trashys.append(child.position.y)
				trashzs.append(child.position.z)
				trashroxs.append(child.rotation.x)
				trashroys.append(child.rotation.y)
				trashrozs.append(child.rotation.z)
		data["vehicle"] = vehicle_data
		data["is_clear"] = is_clear
		data["missing_count"] = missing_count
		data["chx"] = chunkx
		data["chy"] = chunky
		data["ti"] = trashids
		data["tx"] = trashxs
		data["ty"] = trashys
		data["tz"] = trashzs
		data["trx"] = trashroxs
		data["try"] = trashroys
		data["trz"] = trashrozs
		var json_string = JSON.stringify(data)
		dir.store_string(json_string)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("build"):
		if building:
			building = false
			builder.cam.current = false
			cam.current = true
			vehicle = builder.vehicle.duplicate()
			vehicle.player = self
			vehicle.parented_parts = builder.vehicle.parented_parts.duplicate()
			vehicle.reparented_parts = builder.vehicle.reparented_parts.duplicate()
			vehicle.total_power_used = builder.vehicle.total_power_used
			vehicle.position = Vector3(position.x,position.y + 4,position.z)
			if not vehicle.cam:
				vehicle.cam = vehicle.get_node("Camera Arm/Cam")
			if not vehicle.camera_arm:
				vehicle.camera_arm = vehicle.get_node("Camera Arm")
			if vehicle.seat:
				vehicle.camera_arm.position = vehicle.seat.position
			for i in range(vehicle.parented_parts.size()):
				var path_reltative = builder.vehicle.get_path_to(vehicle.parented_parts[i])
				var new_node = vehicle.get_node(path_reltative)
				vehicle.parented_parts[i] = new_node
				path_reltative = builder.vehicle.get_path_to(vehicle.reparented_parts[i])
				new_node = vehicle.get_node(path_reltative)
				vehicle.reparented_parts[i] = new_node
			for child in vehicle.get_children():
				check_magnet(child)
			vehicle.freeze = false
			get_parent().add_child(vehicle)
		else:
			if vehicle:
				vehicle.queue_free()
			building = true
			builder.cam.current = true
			cam.current = false
	if Input.is_action_just_pressed("quit"):
		save()
		get_tree().quit()
	if not building:
		if Input.is_action_just_pressed("drive"):
			if driving:
				collision_layer = 1
				collision_mask = 1
				driving = false
				cam.current = true
				vehicle.cam.current = false
			else:
				collision_layer = 0
				collision_mask = 0
				driving = true
				cam.current = false
				if vehicle.cam:
					vehicle.cam.current = true
		if not driving:
			if Input.is_action_just_pressed("pickup trash"):
				if picked_up_trash:
					picked_up_trash = null
				else:
					var closest_dist : float = INF 
					var closest_trash : Trash = null
					for body in trash_detection_area.get_overlapping_bodies(): 
						if body is Trash: 
							var dist : float = body.position.distance_squared_to(position)
							if dist < closest_dist: 
								closest_dist = dist
								closest_trash = body
					if closest_trash:
						trash_offset = -abs(closest_trash.position-position)
						picked_up_trash = closest_trash
			if picked_up_trash:
				picked_up_trash.position = position + trash_offset
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
		else:
			if vehicle.seat:
				position = vehicle.seat.global_position + (Vector3(0,0.5,0) * vehicle.basis.inverse())
			else:
				position = vehicle.position + Vector3(0,3,0)
			rotation = vehicle.rotation
	move_and_slide()

func check_magnet(node):
	for child in node.get_children():
		check_magnet(child)
	if "Magnet" in node.name:
		node.detatch()
