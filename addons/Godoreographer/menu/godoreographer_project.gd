@tool extends Resource
class_name GodoreographerProject

## Runtime File
#Saved separately for smaller runtime track
@export var runtime_data : SyncedRuntimeTrack
var stream :
	get():
		return runtime_data.audio_stream

## Saved/Loaded
@export var display_name : String
@export var audio_length : float
@export var ui_state : Dictionary # zoom, scroll, etc.
@export var current_level_index : int = 0

# @export Coll. of markers directly on the song
# @export Coll. of Presets
# @export Coll. of used Presets, and where they're used in the song 
# Working Coll. of all markers


## Recalculated on Load
var full_waveform : PackedFloat32Array = []
var waveform_levels : Array[PackedFloat32Array] = [[]]

## Creates new project, after init
func create(_runtime_data : SyncedRuntimeTrack, audio_name : String) -> GodoreographerProject:
	self.runtime_data = _runtime_data
	display_name = audio_name
	audio_length = stream.get_length()
	
	calculate_waveforms()
	return self


## For WaveformDisplay. Recalculated, not saved, way too big
func calculate_waveforms():
	full_waveform = convert_byte_data_to_amplitudes(stream.data)
	
	generate_waveform_levels()
# Converts raw audio stream to an array of samples
func convert_byte_data_to_amplitudes(byte_data : PackedByteArray) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	var sample_count = byte_data.size() / 4  # 4 bytes per stereo frame (2 bytes per channel)
	result.resize(sample_count)
	
	for i in sample_count:
		var left = byte_data.decode_s16(i * 4)
		var right = byte_data.decode_s16((i * 4) + 2)
		var sample = (left + right) / 2 / 32768.0  # Convert to float
		result[i] = abs(sample)

	return result
# Generates max_levels waveforms, each half the length of the previous
# Used for (up to) max_levels levels of zoom, on waveform display
func generate_waveform_levels(max_levels := 8):
	waveform_levels.clear()
	waveform_levels.append(full_waveform)
	
	var current = full_waveform
	
	for i in max_levels:
		var next_level_size = current.size() / 2
		if next_level_size <= 1 : break
		
		var downsampled = downsample(current, int(next_level_size))
		waveform_levels.append(downsampled)
		current = downsampled
func downsample(samples : PackedFloat32Array, target_samples_per_song : int) -> PackedFloat32Array:
	var result = PackedFloat32Array()
	result.resize(target_samples_per_song)
	
	var chunk_size = samples.size() / target_samples_per_song
	
	for i in target_samples_per_song:
		var start = int(i * chunk_size)
		var end = int((i + 1) * chunk_size)
		
		var sum := 0.0
		var count := 0.0
		
		for j in range(start, end):
			if j >= samples.size():
				break
			sum += samples[j]
			count += 1
		
		result[i] = sum / count if (count > 0) else 0.0
	
	
	return result
