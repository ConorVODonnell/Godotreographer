extends Resource
class_name GodoreographerProject

@export var display_name : String
@export var runtime_data : SyncedTrackData
var stream :
	get():
		return runtime_data.audio_stream
@export var audio_length : float
@export var current_waveform : PackedFloat32Array
@export var full_waveform : PackedFloat32Array
@export var waveform_levels : Array[PackedFloat32Array] = []
@export var ui_state : Dictionary # zoom, scroll, etc.


func _init(_runtime_data : SyncedTrackData, audio_name : String) -> void:
	self.runtime_data = _runtime_data
	display_name = audio_name
	
	full_waveform = convert_byte_data_to_amplitudes(stream.data)
	audio_length = stream.get_length()
	
	generate_waveform_levels()


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
