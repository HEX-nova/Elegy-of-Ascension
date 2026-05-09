extends CPUParticles2D

@export var x_variation : float = 50.0
@export var y_variation : float = 20.0

var leaf_region = Rect2(80, 0, 16, 16)
var rain_region = Rect2(32, 0, 16, 16)
var time: float = 0.0
var sig = true

func _process(delta: float) -> void:
	time += delta

	if sig == true:
		if Weather.current_state == Weather.State.CLEAR or Weather.current_state == Weather.State.CLEARCUT:
			amount = 100
		elif Weather.current_state == Weather.State.STORMY or Weather.current_state == Weather.State.STORMYCUT:
			amount = 25000
		else: 
			amount = 50
		# Preprocess makes it look like they've been falling forever when the scene starts
		preprocess = 5.0 
		if Weather.current_state == Weather.State.STORMY:
			global_position = Vector2(global_position.x, global_position.y + -500)
		sig = false

	if Weather.current_state == Weather.State.STORMY or Weather.current_state == Weather.State.STORMYCUT:
		# --- STORM MODE ---
		gravity = Vector2(0, 500) # Use actual gravity for rain
		# Use color to set opacity. alpha 1.0 = fully visible rain.
		color = Color("a5f3fc") 
		scale_amount_min = 0.1
		scale_amount_max = 0.3
		lifetime = 20.0
		if texture is AtlasTexture and texture.region != rain_region:
			texture.region = rain_region
	else:
		# --- LEAF MODE (Serene) ---
		var sway_x = x_variation * sin(time)
		var sway_y = y_variation * sin(time)
		gravity = Vector2(sway_x, sway_y)
		color = Color(0.29, 0.67, 0.4, 1) 
		scale_amount_min = 0.5
		scale_amount_max = 1.0
		lifetime = 20.0
		if texture is AtlasTexture and texture.region != leaf_region:
			texture.region = leaf_region
