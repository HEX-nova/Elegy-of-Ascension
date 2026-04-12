extends Area2D

@export var target_particles: CPUParticles2D 
@export var stats_path: NodePath # Drag your StatsComponent here in the Inspector

var max_distance: float = 0.0
var old_element = -1 # Start at -1 to force an initial update

func _ready():
	var shape = $CollisionShape2D.shape
	if shape is CircleShape2D:
		max_distance = shape.radius
	elif shape is RectangleShape2D:
		max_distance = shape.size.x

func update_shrine_element(current_type):
	var atlas_tex = target_particles.texture as AtlasTexture
	if atlas_tex:
		# We move the 'window' to the X position of the element
		# and keep the window size exactly 1x1 pixels.
		atlas_tex.region = Rect2(current_type, 0, 1, 1)
		print("Switching to Element: ", current_type)

func _process(_delta):
	# Update color if the element changes in Stats
	if StatsComponent:
		var current_element = StatsComponent.element_type
		if current_element != old_element:
			update_shrine_element(current_element)
			old_element = current_element

	# Proximity Logic
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		var t = 1.0 - clamp(dist / max_distance, 0.0, 1.0)
		
		target_particles.modulate.a = lerp(0.7, 1.0, t)
		target_particles.scale_amount_min = lerp(2.5, 5.0, t)
		target_particles.scale_amount_max = lerp(4.0, 8.0, t)
		
		# Glow that doesn't wash out the color
		var glow = lerp(1.0, 2.0, t)
		target_particles.modulate.r = glow
		target_particles.modulate.g = glow
		target_particles.modulate.b = glow
