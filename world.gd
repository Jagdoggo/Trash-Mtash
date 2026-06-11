extends Node3D

@export var trash_scenes : Array[PackedScene]
@export var spawn_size : float = 0
@export var protect_area : float = 2
@export var spawn_count : float = 5

func _ready() -> void:
	for i in range(int(pow(spawn_size,2)*spawn_count)):
		var randx : float = randf_range(-spawn_size,spawn_size)
		var randz : float = randf_range(-spawn_size,spawn_size)
		if abs(randx) < protect_area and abs(randz) < protect_area:
			continue
		var trash : Trash = trash_scenes.pick_random().instantiate()
		trash.position = Vector3(randx,0.7,randz)
		trash.rotation_degrees = Vector3(0,randf_range(1,360),0)
		add_child(trash)

func _process(delta: float) -> void:
	$FPS.text = str(Engine.get_frames_per_second())
