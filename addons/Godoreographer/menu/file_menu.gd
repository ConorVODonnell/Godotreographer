@tool extends PopupMenu

var loaded_project : GodoreographerProject

@onready var wav_dialog: FileDialog = $"../WAVDialog"
@onready var load_dialog: FileDialog = $"../LoadDialog"
#@onready var audio_player: AudioStreamPlayer = $"../../../AudioPlayer"


func _ready() -> void:
	wav_dialog.ok_button_text = "Select Audio"


func _on_file_menu_pressed(index : int):
	match index:
		0 : wav_dialog.popup_centered()
		1 : load_dialog.popup_centered()


func on_WAV_file_selected(path : String):
	print("Selected audio path:", path)	
	var stream : AudioStreamWAV = load(path)
	var runtime_data := SyncedTrackData.new(stream)
	loaded_project = GodoreographerProject.new(runtime_data, path.get_file())


func on_project_selected(path : String):
	pass
