@tool extends PopupMenu

var current_project : GodoreographerProject:
	set(value):
		if current_project != value:
			current_project = value
			$"..".project_changed.emit(current_project)

@onready var wav_dialog: FileDialog = $"../WAVDialog"
@onready var load_dialog: FileDialog = $"../LoadDialog"


func _ready() -> void:
	wav_dialog.ok_button_text = "Select Audio"

# Menu Bar -> File ->
func _on_file_menu_pressed(index : int):
	match index:
		0 : wav_dialog.popup_centered()
		1 : load_dialog.popup_centered()

# -> Create Project -> Select WAV
func on_WAV_file_selected(path : String):
	print("Selected audio path:", path)	
	var stream : AudioStreamWAV = load(path)
	var runtime_data := SyncedTrackData.new(stream)
	current_project = GodoreographerProject.new(runtime_data, path.get_file())

# -> Load Project
func on_project_selected(path : String):
	pass
