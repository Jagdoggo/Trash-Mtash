extends Control

@export var popups : Array[String]
@export var cleared_text : String
@export var popup_cooldown : float = 15
@export var popup_time_enabled : float = 5

@onready var educational_timer: Timer = $"../Educational Timer"
@onready var text: Label = $Text

var is_showing : bool = false

func _ready() -> void:
	educational_timer.start(popup_cooldown)

func cleared():
	educational_timer.stop()
	is_showing = true
	text.show()
	text.text = cleared_text
	educational_timer.start(popup_time_enabled)

func _on_educational_timer_timeout() -> void:
	if is_showing:
		is_showing = false
		text.hide()
		educational_timer.start(popup_cooldown)
	else:
		is_showing = true
		text.text = popups.pick_random()
		text.show()
		educational_timer.start(popup_time_enabled)
