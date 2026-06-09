extends DirectionalLight2D

func _ready() -> void:
	Weather.sky_light = self
	Weather.set_weather(Weather.current_state)
