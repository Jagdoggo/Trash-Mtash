extends Control

@onready var master_slider: HSlider = $Settings/Master/Slider
@onready var music_slider: HSlider = $Settings/Music/Slider
@onready var sounds_slider: HSlider = $Settings/Sounds/Slider
@onready var main_screen: VBoxContainer = $"Main Screen"
@onready var settings: VBoxContainer = $Settings

var state : ui_state

enum ui_state {
	closed,
	main,
	settings
}

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		if state == ui_state.main or state == ui_state.settings:
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
	state = ui_state.main
