extends Control

@export var savegame_path_prefix : String
@export var main_scene_path : String

@onready var save_file_name: TextEdit = $"Buttons/Save File Name"
@onready var tutorial: CheckButton = $Buttons/Tutorial
@onready var file_dialog: FileDialog = $FileDialog

func _on_export_pressed():
	Save.save_path = "user://" + savegame_path_prefix + save_file_name.text + ".json"
	if !FileAccess.file_exists(Save.save_path):
		print("No save exists.")
		return

	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; JSON Save"])
	file_dialog.current_file = "save.json"

	file_dialog.file_selected.disconnect(_export_selected) if file_dialog.file_selected.is_connected(_export_selected) else null
	file_dialog.file_selected.connect(_export_selected, CONNECT_ONE_SHOT)

	file_dialog.popup_centered()


func _export_selected(path:String):
	Save.save_path = "user://" + savegame_path_prefix + save_file_name.text + ".json"
	var src = FileAccess.open(Save.save_path, FileAccess.READ)
	if src == null:
		return

	var dst = FileAccess.open(path, FileAccess.WRITE)
	if dst == null:
		return

	dst.store_string(src.get_as_text())

	src.close()
	dst.close()

	print("Save exported.")


func _on_import_pressed():
	Save.save_path = "user://" + savegame_path_prefix + save_file_name.text + ".json"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; JSON Save"])

	file_dialog.file_selected.disconnect(_import_selected) if file_dialog.file_selected.is_connected(_import_selected) else null
	file_dialog.file_selected.connect(_import_selected, CONNECT_ONE_SHOT)

	file_dialog.popup_centered()


func _import_selected(path:String):
	var src = FileAccess.open(path, FileAccess.READ)
	if src == null:
		return

	var dst = FileAccess.open(Save.save_path, FileAccess.WRITE)
	if dst == null:
		return

	dst.store_string(src.get_as_text())

	src.close()
	dst.close()

	print("Save imported.")

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
