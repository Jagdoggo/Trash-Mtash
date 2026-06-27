extends Control

@export var popups : Array[String]
@export var tutorial_text : Array[String]
@export var cleared_text : String
@export var popup_cooldown : float = 15
@export var popup_time_enabled : float = 5

@onready var educational_timer: Timer = $"../Educational Timer"
@onready var text: Label = $Text

var is_showing : bool = false

signal tutorial_advanced

func _process(delta: float) -> void:
	if Save.is_tutorial and Input.is_action_just_pressed("advance tutorial"):
		tutorial_advanced.emit()

func _ready() -> void:
	educational_timer.start(popup_cooldown)

func cleared():
	educational_timer.stop()
	is_showing = true
	text.show()
	text.text = cleared_text
	educational_timer.start(popup_time_enabled)

func tutorial():
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	educational_timer.stop()
	is_showing = true
	text.show()
	tutorial_repeat(0)

func tutorial_repeat(index):
	text.text = str(tutorial_text[index])
	await tutorial_advanced
	if index + 1 < tutorial_text.size():
		tutorial_repeat(index+1)
	else:
		_on_educational_timer_timeout()

func _on_educational_timer_timeout() -> void:
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if is_showing:
		is_showing = false
		text.hide()
		educational_timer.start(popup_cooldown)
	else:
		is_showing = true
		text.text = popups.pick_random()
		text.show()
		educational_timer.start(popup_time_enabled)
