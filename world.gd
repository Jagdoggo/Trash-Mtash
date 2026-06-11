extends Node3D

@export var player : Node3D
@export var trash_scenes : Array[PackedScene]

@export var chunk_size : float = 5
@export var load_radius : int = 2
@export var trash_per_pile : int = 20
@export var piles_per_chunk : int = 7
@export var pile_varitation : float = 7.5
@export var clear_zone_radius : int = 1

var loaded_chunks : Dictionary = {}
var current_player_chunk : Vector2i = Vector2i(999999, 999999)

func _ready() -> void:
	player.position.x = chunk_size / 2
	player.position.z = chunk_size / 2
	$"Recycling Centre".position.x = chunk_size / 2
	$"Recycling Centre".position.z = chunk_size / 2
	update_chunks()

func _process(delta: float) -> void:
	$FPS.text = str(1/delta)
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
			var chunk := Vector2i(x, z)
			required_chunks[chunk] = true
			if !loaded_chunks.has(chunk):
				spawn_chunk(chunk)
	for chunk in loaded_chunks.keys():
		if !required_chunks.has(chunk):
			despawn_chunk(chunk)

func spawn_chunk(chunk: Vector2i) -> void:
	var chunk_root := Node3D.new()
	chunk_root.name = "Chunk_%d_%d" % [chunk.x, chunk.y]
	add_child(chunk_root)
	loaded_chunks[chunk] = chunk_root
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(chunk.x) + "," + str(chunk.y))
	var trash_scene : PackedScene = trash_scenes.pick_random()
	if abs(chunk.x) < clear_zone_radius and abs(chunk.y) < clear_zone_radius:
		return
	for pi in range(piles_per_chunk):
		var pile_local_x := rng.randf_range(0.0, chunk_size)
		var pile_local_z := rng.randf_range(0.0, chunk_size)
		for ti in range(trash_per_pile):
			var trash : Trash = trash_scene.instantiate()
			var trash_local_x := rng.randf_range(-pile_varitation, pile_varitation)
			var trash_local_y := rng.randf_range(-pile_varitation, pile_varitation)
			var trash_local_z := rng.randf_range(-pile_varitation, pile_varitation)
			trash.position = Vector3(
				chunk.x * chunk_size + pile_local_x + trash_local_x,
				pile_varitation + 1 + trash_local_y,
				chunk.y * chunk_size + pile_local_z + trash_local_z
			)
			trash.rotation_degrees.y = rng.randf_range(0.0, 360.0)
			chunk_root.add_child(trash)

func despawn_chunk(chunk: Vector2i) -> void:
	if !loaded_chunks.has(chunk):
		return
	loaded_chunks[chunk].queue_free()
	loaded_chunks.erase(chunk)
