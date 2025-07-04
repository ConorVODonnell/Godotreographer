@tool extends PopupMenu

var current_project : GodoreographerProject:
	set(value):
		if current_project != value:
			current_project = value
			$"..".project_changed.emit(current_project)
		set_item_disabled(2, value is not GodoreographerProject)
var current_save_path : String = "":
	set(value):
		set_item_disabled(3, value == "")
		current_save_path = value

@onready var wav_dialog: FileDialog = $"../WAVDialog"
@onready var load_dialog: FileDialog = $"../LoadDialog"
@onready var save_as_dialog: FileDialog = $"../SaveAsDialog"


func _ready() -> void:
	wav_dialog.ok_button_text = "Select Audio"
	call_deferred("on_project_selected","res://addons/Godoreographer/resources/sample_save_load.tres")

# Menu Bar -> File ->
func _on_file_menu_pressed(index : int):
	match index:
		0 : wav_dialog.popup_centered()
		1 : load_dialog.popup_centered()
		2 : save_as_dialog.popup_centered()
		3 : on_save_project(current_save_path)

# -> Create Project -> Select WAV
func on_WAV_file_selected(path : String):
	print("Selected audio path:", path)	
	var stream : AudioStreamWAV = load(path)
	var runtime_data := SyncedRuntimeTrack.new().create(stream)
	current_project = GodoreographerProject.new().create(runtime_data, path.get_file())


# -> Load Project
func on_project_selected(path : String):
	var loaded_file= ResourceLoader.load(path)
	
	if loaded_file is GodoreographerProject:	
		loaded_file.calculate_waveforms()
		current_save_path = path
		current_project = loaded_file
	else:
		push_error("Selected file is not a valid GodoreographerProject file.")

# -> Save Project As... / or -> Save Project using cached current_save_path
func on_save_project(path : String):
	print("Saved project to: " + path)
	current_save_path = path
	ResourceSaver.save(current_project, path)
