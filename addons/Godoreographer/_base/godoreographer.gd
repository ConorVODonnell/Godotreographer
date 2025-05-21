@tool
extends Control

@export var load_button: Button
@export var audio_file_dialog: FileDialog
@export var play_pause_button: Button
@export var loaded_file_name: Label
@export var audio_player: AudioStreamPlayer
@onready var waveform_display: WaveformDisplay = $PluginHBox/WaveformViewport/WaveformDisplay

var playback_position := 0.0 :
	set(value):
		playback_position = value
		waveform_display.playhead_time = playback_position


func _ready() -> void:
	load_button.pressed.connect(_on_load_audio_pressed)
	audio_file_dialog.file_selected.connect(_on_audio_file_selected)
	play_pause_button.pressed.connect(_on_play_pause_pressed)
	var top_buttons = $PluginHBox/WaveformViewport/TopButtonContainer
	top_buttons.get_node("ZoomInButton").pressed.connect(waveform_display.zoom_player_display.bind(true))
	top_buttons.get_node("ZoomOutButton").pressed.connect(waveform_display.zoom_player_display.bind(false))
	top_buttons.get_node("PanLeftButton").pressed.connect(pan_player_display.bind(true))
	top_buttons.get_node("PanRightButton").pressed.connect(pan_player_display.bind(false))
	audio_player.finished.connect(set_song_to_zero)
	waveform_display.seek_requested.connect(_on_seek_requested)
	
	# For development
	# Automatically chooses a song when plugin is enabled
	call_deferred("_on_audio_file_selected", "res://addons/Godoreographer/resources/sample Slow Groove with Tempo Change.wav")
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
func _on_load_audio_pressed():
	audio_file_dialog.popup_centered()
func _on_audio_file_selected(path: String):
	print("Selected audio path:", path)
	var stream = load(path)
	
	if stream is AudioStreamWAV:
		audio_player.stream = stream
		loaded_file_name.text = path.get_file()
		
		var full_waveform = convert_byte_data_to_amplitudes(stream.data)
		waveform_display.set_waveform(full_waveform, stream.get_length(), stream.mix_rate)
	else:
		loaded_file_name.text = "Invalid or unsupported audio file"
func convert_byte_data_to_amplitudes(byte_data : PackedByteArray) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	var sample_count = byte_data.size() / 4  # 4 bytes per stereo frame (2 bytes per channel)
	result.resize(sample_count)
	
	for i in sample_count:
		var left = byte_data.decode_s16(i * 4)
		var right = byte_data.decode_s16((i * 4) + 2)
		var sample = (left + right) / 2 / 32768.0  # Convert to float
		result[i] = abs(sample)
	
	#print("Sample count: ", sample_count)
	#print("Byte size: ", byte_data.size())
	#print("10 averaged samples from 60 to 70:")
	#for i in range(60, 70):
		#var left = byte_data.decode_s16(i * 4)
		#var right = byte_data.decode_s16(i * 4 + 2)
		#var avg = (left + right) / 2.0 / 32768.0
		#print("i=", i, " L=", left, " R=", right, " avg=", avg)
	return result
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
