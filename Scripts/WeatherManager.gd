extends Node

# One source of truth
enum State {CLEAR, STORMY, MISTY}
var current_state = State.STORMY

# Shared settings
var cloud_speed_mult: float = 1.0
var cloud_density_mult: float = 1.0
var sky_node: TextureRect
var sky_light: DirectionalLight2D
var sky_modulate: CanvasModulate
var sky_color_top: Color = Color("4ca9ff") # Default Blue
var sky_color_bottom: Color = Color("999999")
var sun_energy: float = 1.0

func set_weather(new_state: int):
	current_state = new_state
	var world_tint: Color = Color(1, 1, 1) # Default: No tint

	match current_state:
		State.CLEAR:
			cloud_speed_mult = 1.0
			cloud_density_mult = 3.0
			sky_color_top = Color("4ca9ff")
			sky_color_bottom = Color("66dcdc")
			sun_energy = 1.2
			world_tint = Color(1, 1, 1) # Clear white light

		State.STORMY:
			cloud_speed_mult = 3.0
			cloud_density_mult = 0.1
			sky_color_top = Color("222222")
			sky_color_bottom = Color("777777")
			sun_energy = 0.4
			world_tint = Color(0.7, 0.7, 0.8) # Slight dark blue/grey tint

		State.MISTY:
			cloud_speed_mult = 0.3
			cloud_density_mult = 2.0
			sky_color_top = Color("a8b1b5")
			sky_color_bottom = Color("999999")
			sun_energy = 0.7
			world_tint = Color(0.8, 0.8, 0.85) # The foggy tint

	# Update the Sky Texture
	if sky_node and sky_node.texture is GradientTexture2D:
		if sky_node.texture.gradient == null:
			sky_node.texture.gradient = Gradient.new()
		sky_node.texture.gradient.set_color(0, sky_color_top)
		sky_node.texture.gradient.set_color(1, sky_color_bottom)
	if sky_light:
		sky_light.energy = sun_energy
	if sky_modulate:
		sky_modulate.color = world_tint
