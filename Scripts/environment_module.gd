extends WorldEnvironment

@export var state : Weather.State = Weather.State.CLEAR

func _ready() -> void:
	Weather.sky_modulate = $CanvasModulate
	Weather.set_weather(state)
