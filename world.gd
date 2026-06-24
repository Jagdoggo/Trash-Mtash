extends Node3D

class chunk_clear_progress:
	var ammount_missing : int
	var cleared_node : MeshInstance3D
"[(1.842135, 0.542726, 1.037133), (-0.625493, -0.896425, 2.173268), (0.579339, -0.272132, 1.097219), (0.668658, -1.162221, -3.039837), (2.209369, -1.192834, -0.692266), (1.318351, 0.157107, 1.331866), (0.646453, 0.207958, 0.760125), (-1.050645, -1.237232, -0.277877), (0.553609, -1.238638, -1.146204), (-2.11991, -1.249188, 1.388757), (0.347716, -0.161873, -1.158571), (0.071748, -0.993218, -0.245499), (-0.04527, -1.15184, -1.941032), (-0.521382, 0.410433, 0.652238), (-0.466159, -0.668162, -0.532954), (-0.486632, -0.463803, 1.209645), (0.973578, -0.781691, -0.578568), (1.01323, -1.248785, -0.049315), (0.652055, -1.214733, -0.465852), (0.49388, -1.193536, -2.127033), (0.440927, -1.270312, 0.199527), (0.96573, -1.128448, 2.440124), (1.012177, -0.773003, 0.730693), (-1.141429, -1.250632, 0.816232), (-0.547557, -1.236377, -1.439778), (-0.370936, -1.270347, 0.607989), (0.863053, -1.154015, -1.75604), (-0.989749, -0.723472, 0.422147), (0.651549, -1.269185, 0.711763), (-0.171134, -1.100147, 0.152866), (-2.232581, -1.228239, 0.591428), (-0.607129, -1.119925, 1.046378), (-0.228982, -0.528903, 0.174491), (-0.171777, 0.021775, 1.070384), (1.348506, -1.252467, -1.31752), (1.389632, -1.168267, -0.747298), (1.526137, 0.140832, 0.554608), (-0.843162, -1.225581, 0.430915), (0.582202, -0.739528, -1.16978), (0.419467, -0.30073, 0.385465), (-0.813504, 0.428767, 0.052064), (-0.004329, 0.085812, 0.534793), (-0.202626, 0.423478, -0.36262), (0.039451, -1.147076, -0.860606), (3.43009, -1.211854, -1.176744), (-1.19933, -0.734452, -0.225026), (0.000754, -0.753064, 0.773656), (-0.462779, -0.111362, -0.456712), (-0.666144, 0.705996, 1.065755), (0.942088, 0.258549, -0.061871), (0.679469, 0.743227, 0.21984), (0.623519, -0.19901, -0.208903), (-1.291774, -1.207907, 1.654931), (0.333152, -0.613205, -0.576943), (-2.231011, -1.250004, -1.595658), (0.541333, -0.777567, 0.530784), (-0.741231, -0.53817, -0.009341), (0.590581, -1.262795, 1.262965), (0.0831, -1.269801, 0.867843), (1.071523, -1.256156, 0.46551), (0.620246, 0.199477, -0.663412), (-0.796823, -1.250429, -0.827944), (1.326535, -0.323753, 0.946702), (0.344987, 0.399912, 1.197427), (-0.648864, -1.028862, -0.003659), (-0.588809, -1.067462, 2.800168), (-0.920367, -0.758918, 1.345492), (0.44391, 0.254882, 0.160098), (-1.262418, -0.735323, -1.030515), (1.01847, -0.297383, 0.285226), (-0.371377, -1.251906, -0.426724), (0.07722, -0.186894, -0.264859), (1.138263, -0.565996, -2.011696), (0.225242, -1.139773, 2.850568), (1.082128, -0.283855, -0.915832), (0.429601, -0.764068, 1.335338), (-1.608191, -1.249233, -1.108065), (0.274009, -0.799536, -2.591426), (-1.020072, -0.083172, -0.041934), (-0.917823, 0.89845, 0.178455)]"
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
		for ti in range(trash_per_pile):
			current_trash_id += 1
			if not current_trash_id > total:
				var trash : Trash = trash_scene.instantiate()
				trash.set_meta("t_index", mesh_index)
				trash.set_meta("locx",chunk.x * chunk_size + pile_local_x)
				trash.set_meta("locz",chunk.y * chunk_size + pile_local_z)
				var trash_local_x := rng.randf_range(-pile_varitation, pile_varitation)
				var trash_local_y := rng.randf_range(-pile_varitation, pile_varitation)
				var trash_local_z := rng.randf_range(-pile_varitation, pile_varitation)
				#var trash_local_x = pile_positions[current_trash_id-1].x
				#var trash_local_y = pile_positions[current_trash_id-1].y
				#var trash_local_z = pile_positions[current_trash_id-1].z
				trash.position = Vector3(
					chunk.x * chunk_size + pile_local_x + trash_local_x,
					trash_local_y,
					chunk.y * chunk_size + pile_local_z + trash_local_z
				)
				trash.rotation_degrees.y = rng.randf_range(0.0, 360.0)
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
	var positions = []
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
				trash.collision_mask = 1
				trash.collision_layer = 1
				trash.reparent(self)
			else:
				positions.append(Vector3(
					trash.position.x - trash.get_meta("locx"),
					trash.position.y,
					trash.position.z - trash.get_meta("locz")
					))
	print(positions)
	loaded_chunks[chunk].queue_free()
	loaded_chunks.erase(chunk)
