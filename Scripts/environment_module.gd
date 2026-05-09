extends WorldEnvironment

@export var state : Weather.State = Weather.State.CLEAR

func _ready() -> void:
	Weather.sky_modulate = $CanvasModulate
	Weather.sky_node = get_tree().get_first_node_in_group("Sky")
	Weather.set_weather(state)
	if state == Weather.State.CLEARCUT or state == Weather.State.STORMYCUT or state == Weather.State.MISTYCUT :
		environment.glow_enabled = true
	else :
		environment.glow_enabled = false
