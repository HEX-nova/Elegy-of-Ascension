extends Node2D

@export var death_pos: float = 2500 
@export var speed_min: float = 20.0
@export var speed_max: float = 60.0

var stormy: bool = false # Match the name used in the generator
var current_speed: float

func _ready() -> void:
	# 1. Determine State from the Global Manager
	stormy = (Weather.current_state == Weather.State.STORMY)
	
	# 2. Visual Variation (Picking the sprite)
	var cloud_variants = [$"01", $"02", $"03"]
	var winner_index = randi() % cloud_variants.size()
	for i in range(cloud_variants.size()):
		cloud_variants[i].visible = (i == winner_index)

	# 3. Size & Speed based on Weather
	var s: float = 0.3
	if stormy:
		s = randf_range(2.0, 6.0) # Massive storm clouds
		# Multiply base random speed by the global weather speed multiplier
		current_speed = randf_range(speed_min, speed_max) * Weather.cloud_speed_mult
	else:
		s = randf_range(0.3, 1.3) # Regular drifters
		current_speed = randf_range(speed_min, speed_max)
	scale = Vector2(randf_range(s, s*2), randf_range(s, s))
	
	# Debug info to console
	print("Cloud Type: ", "Storm" if stormy else "Clear", " | Speed: ", current_speed)

func _process(delta: float) -> void:
	position.x += current_speed * delta
	if position.x > death_pos:
		print("Cloud deleted ! last location : ", global_position)
		queue_free()
