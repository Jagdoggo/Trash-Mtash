extends CollisionShape3D

@export var runtime : float = 60
@export var power_gained : float = 4

@onready var runtime_timer: Timer = $"Runtime Timer"

var vehicle : VehicleBody3D
var generating : bool = false
var was_generating : bool = false
var was_stopped : bool = true

func _process(delta: float) -> void:
	var toggled : bool = false
	#if Input.is_action_just_pressed("toggle generator"):
		#if !generating:
			#toggled = true
			#runtime_timer.start(runtime)
			#generating = true
			#print("started")
	if not vehicle:
		var current_node = get_parent()
		var running = true
		while running:
			if current_node is VehicleBody3D:
				vehicle = current_node
				running = false
			else:
				current_node = current_node.get_parent()
	if runtime_timer.is_stopped() != was_stopped and !toggled:
		generating = false
		print("stopped")
	if generating != was_generating:
		vehicle.total_power_used += power_gained * (int(generating)*2 - 1)
	was_generating = generating
	was_stopped = runtime_timer.is_stopped()
	toggled = false
