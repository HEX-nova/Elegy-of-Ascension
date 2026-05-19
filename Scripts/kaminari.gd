extends Line2D

@export var start_node: Node2D
@export var end_node: Node2D

@export_group("Bolt Settings")
@export var segment_unit_length: float = 20.0 # One segment every 20 pixels
@export var amplitude: float = 25.0
@export var fire_rate: float = 0.1 # Seconds between strikes
@export var flash_duration: float = 0.05 # How long the bolt stays visible

var timer: float = 0.0
var flash_timer: float = 0.0

func _ready():
	# Use a high raw value for the color so it glows without washing out the screen
	# This requires WorldEnvironment Glow Threshold to be around 1.0
	self.default_color = Color(1.5, 1.5, 5.0, 1.0) # Intense HDR Blue
	clear_points()

func _process(delta):
	timer += delta
	
	# Handle Fire Rate
	if timer >= fire_rate:
		generate_lightning()
		timer = 0.0
		flash_timer = flash_duration
	
	# Handle the "Flash" disappearance
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			clear_points()

func generate_lightning():
	if !start_node or !end_node: return
	
	clear_points()
	var start_pos = start_node.global_position
	var end_pos = end_node.global_position
	
	var diff = end_pos - start_pos
	var distance = diff.length()
	var direction = diff.normalized()
	var normal = Vector2(-direction.y, direction.x)
	
	# Dynamic Segments based on distance
	var segment_count = max(2, int(distance / segment_unit_length))
	var actual_step = distance / segment_count
	
	add_point(to_local(start_pos))
	
	for i in range(1, segment_count):
		var base_pos = start_pos + (direction * actual_step * i)
		# Jitter the point
		var offset = normal * randf_range(-amplitude, amplitude)
		add_point(to_local(base_pos + offset))
		
	add_point(to_local(end_pos))
