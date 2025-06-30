extends Resource
class_name SyncedRuntimeTrack

@export var audio_stream : AudioStreamWAV
@export var markers : Array


func create(_audio_stream : AudioStreamWAV) -> SyncedRuntimeTrack:
	self.audio_stream = _audio_stream
	return self
