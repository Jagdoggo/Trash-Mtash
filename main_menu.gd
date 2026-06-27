extends Control

@export var savegame_path_prefix : String
@export var main_scene_path : String

@onready var save_file_name: TextEdit = $"Buttons/Save File Name"
@onready var tutorial: CheckButton = $Buttons/Tutorial

func delete():
	var dir = DirAccess.open("user://")
	if dir:
		var full_path = "user://" + savegame_path_prefix + save_file_name.text + ".json"
		if dir.file_exists(full_path):
			var error = dir.remove(full_path)
			if error == OK:
				print("Save file deleted successfully: ", full_path)
			else:
				print("Error deleting save file: ", error)
		else:
			print("Save file not found: ", full_path)
	else:
		print("Error opening user directory.")

func _on_play_pressed() -> void:
	Save.save_path = "user://" + savegame_path_prefix + save_file_name.text + ".json"
	Save.is_tutorial = tutorial.button_pressed
	get_tree().change_scene_to_file(main_scene_path)

func _on_reset_pressed() -> void: 
	delete()

func _on_quit_pressed() -> void:
	get_tree().quit()
