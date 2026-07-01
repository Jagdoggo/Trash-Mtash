extends Control

@export_multiline() var options : Array[String]

@onready var master_slider: HSlider = $Settings/Master/Slider
@onready var music_slider: HSlider = $Settings/Music/Slider
@onready var sounds_slider: HSlider = $Settings/Sounds/Slider
@onready var main_screen: VBoxContainer = $"Main Screen"
@onready var settings: VBoxContainer = $Settings
@onready var help: VBoxContainer = $Help
@onready var info: Label = $Help/Info
@onready var small_info: Label = $"../Educational/VBoxContainer/Small Info"

var state : ui_state

enum ui_state {
	closed,
	main,
	settings,
	help
}

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		if state == ui_state.main or state == ui_state.settings or state == ui_state.help:
			_on_resume_pressed()
		else:
			_on_back_pressed()
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			show()
	if state == ui_state.settings:
		AudioServer.set_bus_volume_linear(0,master_slider.value)
		AudioServer.set_bus_volume_linear(1,music_slider.value)
		AudioServer.set_bus_volume_linear(2,sounds_slider.value)

func _on_resume_pressed() -> void:
	state = ui_state.closed
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()

func _on_settings_pressed() -> void:
	main_screen.hide()
	settings.show()
	state = ui_state.settings

func _on_back_pressed() -> void:
	main_screen.show()
	settings.hide()
	help.hide()
	state = ui_state.main

func _on_help_pressed() -> void:
	main_screen.hide()
	help.show()
	state = ui_state.help

func _on_option_select_item_selected(index: int) -> void:
	if options[index]:
		info.text = options[index]
		small_info.text = options[index]
		#small_info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		#update_ui.call_deferred()
#
#func update_ui():
	#small_info.offset_left = -small_info.size.x
	#small_info.offset_right = small_info.size.x
	#small_info.offset_top = small_info.size.y
	#small_info.offset_bottom = -small_info.size.y
