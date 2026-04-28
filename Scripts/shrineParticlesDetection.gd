extends Area2D

@export var target_particles: CPUParticles2D 
@export var target_particles2: CPUParticles2D

var max_distance: float = 0.0

func _ready():
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
		# Move the atlas window to the shrine's fixed element
		atlas_tex.region = Rect2(current_type, 0, 1, 1)
		print("Shrine Particles set to Element: ", current_type)

func _process(_delta):
	# Proximity Logic stays the same, but we removed the StatsComponent check
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		var t = 1.0 - clamp(dist / max_distance, 0.0, 1.0)
		target_particles.amount = lerp(0.1, 1.0, t)
		target_particles.modulate.a = lerp(0.7, 1.0, t)
		target_particles.scale_amount_min = lerp(1.0, 4.0, t)
		target_particles.scale_amount_max = lerp(3.0, 8.0, t)
		
		target_particles2.amount = lerp(0.1, 1.0, t)
		target_particles2.modulate.a = lerp(0.7, 1.0, t)
		target_particles2.scale_amount_min = lerp(1.0, 4.0, t)
		target_particles2.scale_amount_max = lerp(3.0, 8.0, t)
		
		# Glow modulation
		var glow = lerp(1.0, 2.0, t)
		target_particles.self_modulate = Color(glow, glow, glow, 1.0)
		target_particles2.self_modulate = Color(glow, glow, glow, 1.0)
