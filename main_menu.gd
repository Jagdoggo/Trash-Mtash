extends Control

@export var savegame_path_prefix : String
@export var main_scene_path : String

@onready var save_file_name: TextEdit = $"Buttons/Save File Name"
@onready var tutorial: CheckButton = $Buttons/Tutorial
@onready var file_dialog: FileDialog = $FileDialog
@onready var imported: Label = $Buttons/Imported

# Keep a class-level reference to the callback so the garbage collector doesn't clear it
var web_import_callback: JavaScriptObject

func _ready():
	if OS.has_feature("web"):
		get_window().files_dropped.connect(_on_files_dropped)
		
		# Create the callback once and store it safely in memory
		web_import_callback = JavaScriptBridge.create_callback(_web_import_finished)
		
		# Define the JS function globally once on ready
		JavaScriptBridge.eval("""
			window.importSave = function(callback) {
				console.log("importSave triggered");

				let input = document.getElementById('godot_web_import_input');
				if (!input) {
					input = document.createElement("input");
					input.id = 'godot_web_import_input';
					input.type = "file";
					input.accept = ".json";
					input.style.display = "none";
					document.body.appendChild(input);
				}

				// Reset the value so selecting the same file twice still triggers onchange
				input.value = "";

				input.onchange = function(event) {
					console.log("File selected inside browser");
					
					const file = event.target.files[0];
					if (!file) return;

					const reader = new FileReader();
					reader.onload = function(e) {
						console.log("File read successfully inside browser");
						callback([e.target.result]);
					};

					reader.onerror = function(err) {
						console.error("Browser read error:", err);
					};

					reader.readAsText(file);
				};

				input.click();
			};
		""", true)

func _on_files_dropped(files: PackedStringArray) -> void:
	Save.save_path = "user://" + savegame_path_prefix + save_file_name.text + ".json"
	if files.is_empty():
		return
	# FIXED: files[0] targets the specific dropped file path string instead of the entire array layout
	var src := FileAccess.open(files[0], FileAccess.READ)
	if src == null:
		push_error("Couldn't open dropped file.")
		return
	var dst := FileAccess.open(Save.save_path, FileAccess.WRITE)
	if dst == null:
		push_error("Couldn't open save file.")
		return
	dst.store_string(src.get_as_text())
	src.close()
	dst.close()
	print("Save imported!")
	imported.show()
	await get_tree().create_timer(5).timeout
	imported.hide()

func _on_export_pressed():
	Save.save_path = "user://" + savegame_path_prefix + save_file_name.text + ".json"

	if OS.has_feature("web"):
		if !FileAccess.file_exists(Save.save_path):
			print("No save exists.")
			return

		var file := FileAccess.open(Save.save_path, FileAccess.READ)
		var text := file.get_as_text()
		file.close()

		JavaScriptBridge.eval("""
			window.downloadSave = function(text, filename) {
				const blob = new Blob([text], {type: "application/json"});
				const url = URL.createObjectURL(blob);

				const a = document.createElement("a");
				a.href = url;
				a.download = filename;
				a.click();

				URL.revokeObjectURL(url);
			};
		""", true)

		JavaScriptBridge.get_interface("window").downloadSave(
			text,
			save_file_name.text + ".json"
		)

		print("Save exported!")
		return

	# Desktop
	if !FileAccess.file_exists(Save.save_path):
		print("No save exists.")
		return

	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; JSON Save"])
	file_dialog.current_file = save_file_name.text + ".json"

	if file_dialog.file_selected.is_connected(_export_selected):
		file_dialog.file_selected.disconnect(_export_selected)

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

	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("window").importSave(web_import_callback)
		return

	# Desktop
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; JSON Save"])

	if file_dialog.file_selected.is_connected(_import_selected):
		file_dialog.file_selected.disconnect(_import_selected)

	file_dialog.file_selected.connect(_import_selected, CONNECT_ONE_SHOT)
	file_dialog.popup_centered()

func _web_import_finished(args):
	print("Callback args received:", args)

	if args.is_empty() or args[0] == null:
		push_error("No data received from JavaScript!")
		return

	# FIXED: Unpack the JavaScriptObject wrapper into a standard GDScript string
	var json_text: String = ""
	if args[0] is JavaScriptObject:
		json_text = args[0].toString()
	else:
		json_text = str(args[0])

	print("JSON string length:", json_text.length())

	var dst := FileAccess.open(Save.save_path, FileAccess.WRITE)
	if dst == null:
		push_error("Couldn't open save file.")
		return

	dst.store_string(json_text)
	dst.close()

	print("Save successfully imported to user:// !")

	imported.show()
	await get_tree().create_timer(5).timeout
	imported.hide()

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
	imported.show()
	await get_tree().create_timer(5).timeout
	imported.hide()

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
