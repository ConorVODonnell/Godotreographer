extends Resource
class_name SyncedTrackData

@export var audio_stream : AudioStreamWAV
@export var markers : Array


func _init(_audio_stream : AudioStreamWAV) -> void:
	self.audio_stream = _audio_stream
