extends Node3D

class chunk_clear_progress:
	var ammount_missing : int
	var cleared_node : MeshInstance3D

@export var player : Node3D
@export var cleared_scene : PackedScene
@export var trash_scenes : Array[PackedScene]
@export var trash_meshes : Array[Mesh]

@export var chunk_size : float = 5
@export var load_radius : int = 2
@export var trash_per_pile : int = 20
@export var piles_per_chunk : int = 7
@export var pile_varitation : float = 7.5
@export var clear_zone_radius : int = 1
@export var save_file_name : String
@export var pile_positions : Array[Vector3]
@export var pile_rotations : Array[Vector3]

class chunk_multimesh:
	var multimesh_nodes : Array[MultiMeshInstance3D]
	var chunk_node : Node3D

var loaded_chunks : Dictionary = {}
var loaded_chunk_multimesh_objs : Array[chunk_multimesh]
var all_chunk_clear_progress : Dictionary[Vector2i,chunk_clear_progress]
var current_player_chunk : Vector2i = Vector2i(999999,999999)

func _ready() -> void:
	assert(
		trash_scenes.size() == trash_meshes.size(),
		"trash_scenes and trash_meshes must have the same size"
	)
	player.position.x = (chunk_size / 2) - 7
	player.position.z = (chunk_size / 2)
	$"Recycling Centre".position.x = chunk_size / 2
	$"Recycling Centre".position.z = chunk_size / 2
	update_chunks()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("complete"):
		all_chunk_clear_progress[current_player_chunk].ammount_missing = 1000
	for chunk_data in loaded_chunk_multimesh_objs:
		var mesh_indices : Array[int] = []
		for i in range(trash_meshes.size()):
			mesh_indices.append(0)
		for trash in chunk_data.chunk_node.get_children():
			if !trash.has_meta("t_index"):
				continue
			var mesh_idx : int = trash.get_meta("t_index")
			if mesh_idx >= chunk_data.multimesh_nodes.size():
				continue
			var instance_idx : int = mesh_indices[mesh_idx]
			if instance_idx < chunk_data.multimesh_nodes[mesh_idx].multimesh.instance_count:
				chunk_data.multimesh_nodes[mesh_idx].multimesh.set_instance_transform(
					instance_idx,
					trash.global_transform
				)
			mesh_indices[mesh_idx] += 1
	$FPS.text = str(round(1.0 / delta))
	var new_chunk := get_chunk(player.global_position)
	if new_chunk != current_player_chunk:
		current_player_chunk = new_chunk
		update_chunks()

func get_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(
		floor(pos.x / chunk_size),
		floor(pos.z / chunk_size)
	)

func update_chunks() -> void:
	var center := get_chunk(player.global_position)
	var required_chunks := {}
	for x in range(center.x - load_radius, center.x + load_radius + 1):
		for z in range(center.y - load_radius, center.y + load_radius + 1):
			var chunk := Vector2i(x,z)
			required_chunks[chunk] = true
			if !loaded_chunks.has(chunk):
				spawn_chunk(chunk)
	var chunks_to_remove : Array[Vector2i] = []
	for chunk in loaded_chunks.keys():
		if !required_chunks.has(chunk):
			chunks_to_remove.append(chunk)
	for chunk in chunks_to_remove:
		despawn_chunk(chunk)
	rebuild_all_multimeshes()

func rebuild_all_multimeshes() -> void:
	for chunk_data in loaded_chunk_multimesh_objs:
		for mm in chunk_data.multimesh_nodes:
			if is_instance_valid(mm):
				mm.queue_free()
	loaded_chunk_multimesh_objs.clear()
	for chunk_node in loaded_chunks.values():
		create_chunk_multimeshes(chunk_node)

func create_chunk_multimeshes(chunk_node : Node3D) -> void:
	var chunk_data := chunk_multimesh.new()
	chunk_data.chunk_node = chunk_node
	for mesh_idx in range(trash_meshes.size()):
		var transforms : Array[Transform3D] = []
		for trash in chunk_node.get_children():
			if !trash.has_meta("t_index"):
				continue
			if trash.get_meta("t_index") == mesh_idx:
				transforms.append(trash.global_transform)
		var mm := MultiMesh.new()
		mm.mesh = trash_meshes[mesh_idx]
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = transforms.size()
		mm.visible_instance_count = transforms.size()
		for i in range(transforms.size()):
			mm.set_instance_transform(i, transforms[i])
		var mm_instance := MultiMeshInstance3D.new()
		mm_instance.multimesh = mm
		add_child(mm_instance)
		chunk_data.multimesh_nodes.append(mm_instance)
	loaded_chunk_multimesh_objs.append(chunk_data)

func spawn_chunk(chunk: Vector2i) -> void:
	var progress_obj : chunk_clear_progress
	if chunk in all_chunk_clear_progress.keys():
		progress_obj = all_chunk_clear_progress[chunk]
	else:
		progress_obj = chunk_clear_progress.new()
		progress_obj.ammount_missing = 0
	all_chunk_clear_progress[chunk] = progress_obj
	var chunk_root := Node3D.new()
	chunk_root.name = "Chunk_%d_%d" % [chunk.x, chunk.y]
	add_child(chunk_root)
	loaded_chunks[chunk] = chunk_root
	if abs(chunk.x) < clear_zone_radius and abs(chunk.y) < clear_zone_radius:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(chunk.x) + "," + str(chunk.y))
	var mesh_index := randi_range(0, trash_scenes.size() - 1)
	var trash_scene : PackedScene = trash_scenes[mesh_index]
	var current_trash_id : int = 0
	var total = (piles_per_chunk * trash_per_pile) - progress_obj.ammount_missing
	if progress_obj.cleared_node:
		return
	if total <= 0:
		player.educational.cleared()
		var cleared_node : MeshInstance3D = cleared_scene.instantiate()
		cleared_node.position = Vector3(chunk.x * chunk_size+chunk_size/2,-1.9,chunk.y * chunk_size+chunk_size/2)
		cleared_node.scale = Vector3(chunk_size,1,chunk_size)
		progress_obj.cleared_node = cleared_node
		add_child(cleared_node)
		return
	for pi in range(piles_per_chunk):
		var pile_local_x := rng.randf_range(0.0, chunk_size)
		var pile_local_z := rng.randf_range(0.0, chunk_size)
		var pile_pos_index : int = 0
		for ti in range(trash_per_pile):
			pile_pos_index += 1
			current_trash_id += 1
			if not current_trash_id > total:
				var trash : Trash = trash_scene.instantiate()
				trash.set_meta("t_index", mesh_index)
				var trash_local_x = pile_positions[pile_pos_index-1].x
				var trash_local_y = pile_positions[pile_pos_index-1].y
				var trash_local_z = pile_positions[pile_pos_index-1].z
				trash.player_node = player
				trash.position = Vector3(
					chunk.x * chunk_size + pile_local_x + trash_local_x,
					trash_local_y,
					chunk.y * chunk_size + pile_local_z + trash_local_z
				)
				trash.rotation = pile_rotations[pile_pos_index-1]
				chunk_root.add_child(trash)

func despawn_chunk(chunk: Vector2i) -> void:
	if !loaded_chunks.has(chunk):
		return
	for chunk_data in loaded_chunk_multimesh_objs:
		if chunk_data.chunk_node == loaded_chunks[chunk]:
			for mm in chunk_data.multimesh_nodes:
				if is_instance_valid(mm):
					mm.queue_free()
			loaded_chunk_multimesh_objs.erase(chunk_data)
			break
	for trash in loaded_chunks[chunk].get_children():
		if trash is Trash:
			if trash.protected_from_despawn and trash.position.distance_to(player.position) < chunk_size:
				var progress_obj : chunk_clear_progress = all_chunk_clear_progress[chunk]
				progress_obj.ammount_missing += 24
				var trash_mesh : MeshInstance3D = MeshInstance3D.new()
				trash_mesh.mesh = trash_meshes[trash.get_meta("t_index")]
				trash.add_child(trash_mesh)
				trash.sleeping = false
				trash.get_node("VisibleOnScreenEnabler3D").free()
				trash.process_mode = Node.PROCESS_MODE_ALWAYS
				trash.freeze = false
				trash.is_magneted = false
				trash.collision_mask = 1
				trash.collision_layer = 1
				trash.reparent(self)
	loaded_chunks[chunk].queue_free()
	loaded_chunks.erase(chunk)
