@tool
extends Control

var project : GodoreographerProject:
	set(value):
		project = value
		waveform_display.project = project
		
		if not project: return
		audio_player.stream = project.stream
		loaded_file_name.text = project.display_name
		#loaded_file_name.text = path.get_file()
@onready var menu_bar: GodoreographerMenuBar = $VBoxContainer/MenuBar
@export var play_pause_button: Button
@export var loaded_file_name: Label
@export var audio_player: AudioStreamPlayer
@onready var waveform_display: WaveformDisplay = $VBoxContainer/PluginHBox/WaveformViewport/Control/WaveformDisplay

var playback_position := 0.0 :
	set(value):
		playback_position = value
		waveform_display.playhead_time = playback_position


func _ready() -> void:
	play_pause_button.pressed.connect(_on_play_pause_pressed)
	var top_buttons = $VBoxContainer/PluginHBox/WaveformViewport/TopButtonContainer
	top_buttons.get_node("ZoomInButton").pressed.connect(waveform_display.zoom_player_display.bind(true))
	top_buttons.get_node("ZoomOutButton").pressed.connect(waveform_display.zoom_player_display.bind(false))
	top_buttons.get_node("PanLeftButton").pressed.connect(pan_player_display.bind(true))
	top_buttons.get_node("PanRightButton").pressed.connect(pan_player_display.bind(false))
	audio_player.finished.connect(set_song_to_zero)
	waveform_display.seek_requested.connect(_on_seek_requested)
	
	menu_bar.project_changed.connect(func(new_project): project = new_project)
	
	# For development
	# Automatically chooses a song when plugin is enabled
	#call_deferred("_on_audio_file_selected", "res://addons/Godoreographer/resources/sample Slow Groove with Tempo Change.wav")
	focus_mode = Control.FOCUS_CLICK


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		grab_focus()


func _process(delta: float) -> void:
	if audio_player.playing:
		var current_time = audio_player.get_playback_position()
		waveform_display.playhead_time = current_time
		
		# auto-follow playhead, otherwise the playhead disappears
		var playhead_rel = (current_time - waveform_display.visible_start) / waveform_display.range
		if playhead_rel > 0.7:
			waveform_display.visible_start = current_time - (0.2 * waveform_display.range)


## Select new song
func _on_marker_type_dropdown_item_selected(index):
	var type_string = $MarkerTypeDropdown.get_item_text(index)
	if waveform_display.selected_marker:
		waveform_display.selected_marker.type = type_string
		waveform_display.queue_redraw()

##  Handle User Input
func _on_play_pause_pressed():
	if audio_player.playing:
		playback_position = audio_player.get_playback_position()
		audio_player.stop()
		play_pause_button.text = "Play"
	else:
		audio_player.play(playback_position)
		play_pause_button.text = "Pause"
func pan_player_display(pan_left):
	var pan_amount = waveform_display.range * 0.1  # move 10% of display range
	
	if pan_left:
		waveform_display.visible_start -= pan_amount
	else:
		waveform_display.visible_start += pan_amount
	waveform_display.queue_redraw()
func _on_seek_requested(time: float):
	var was_playing = audio_player.playing
	audio_player.play(time)
	if not was_playing: _on_play_pause_pressed()

## Helper
func set_song_to_zero():
	play_pause_button.text = "Play"
	playback_position = 0.0
