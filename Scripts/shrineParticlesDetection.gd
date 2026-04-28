extends Area2D

@export var target_particles: CPUParticles2D
@export var target_particles2: CPUParticles2D
var player : CharacterBody2D

var max_distance: float = 0.0
var pos : Vector2

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	target_particles = $"Energy particles"
	target_particles2 = $"Energy particles2"
	
	pos = target_particles.global_position
	# 1. Get distance for proximity logic
	var shape = $CollisionShape2D.shape
	if shape is CircleShape2D:
		max_distance = shape.radius
	elif shape is RectangleShape2D:
		max_distance = shape.size.x
	
	# 2. Grab the element from the parent (The Shrine)
	# This assumes the parent has 'var shrine_element'
	if get_parent() and "shrine_element" in get_parent():
		var element = get_parent().shrine_element
		update_shrine_element(element)

func update_shrine_element(current_type):
	var atlas_tex = target_particles.texture as AtlasTexture
	if atlas_tex:
		var sprite_size = 16 
		atlas_tex.region = Rect2(current_type * sprite_size, 0, sprite_size, sprite_size)
	
	# --- 1. ROTATION LOGIC ---
	# We set these once so the particles spin naturally
	for p in [target_particles, target_particles2]:
		p.angle_min = -180.0
		p.angle_max = 180.0
		p.angular_velocity_min = 20.0 # Slow spin
		p.angular_velocity_max = 200.0 # Faster spin
	
	# --- 2. GRAVITY LOGIC (Dendro: 1, Geo: 4, Anemo: 5) ---
	var fall_elements = [1, 4, 5]
	var gravity_value = 98.0 # Positive falls down
	
	if current_type in fall_elements:
		target_particles.gravity = Vector2(0, gravity_value)
		target_particles2.gravity = Vector2(0, gravity_value)
		target_particles.global_position = pos + Vector2(0, -200)
		target_particles2.global_position = pos + Vector2(0, -200)
	else:
		target_particles.gravity = Vector2(0, -gravity_value) # Negative floats up
		target_particles2.gravity = Vector2(0, -gravity_value)
		target_particles.global_position = pos
		target_particles2.global_position = pos

func _process(_delta):
	if player:
		var dist = global_position.distance_to(player.global_position)
		var t = 1.0 - clamp(dist / max_distance, 0.0, 1.0)
		
		var alpha_fade = lerp(0.5, 1.0, t)
		
		var s_min = lerp(0.1, 0.5, t)
		var s_max = lerp(0.4, 0.7, t)
		
		for p in [target_particles, target_particles2]:
			p.modulate.a = alpha_fade
			p.scale_amount_min = s_min
			p.scale_amount_max = s_max
			var glow = lerp(1.0, 3.0, t)
			p.self_modulate = Color(glow, glow, glow, alpha_fade)
