extends Node2D

### The smaller this var is, the denser the clouds are
@export var cloud_density : float = 2.0
@export var cloud_scene: PackedScene 

func _ready() -> void:
	$Timer.start()
	
	# 1. Get all nodes in the Sky group
	var sky_elements = get_tree().get_nodes_in_group("Sky")
	
	# 2. Sort them into the correct Weather slots
	for element in sky_elements:
		if element is TextureRect:
			Weather.sky_node = element
		elif element is DirectionalLight2D:
			Weather.sky_light = element
			
	# 3. Apply the initial weather settings ONCE
	Weather.set_weather(Weather.current_state)

func _on_timer_timeout() -> void:
	if cloud_scene:
		var new_cloud = cloud_scene.instantiate()
		var spawn_y = randi_range(global_position.y -650, global_position.y -400)
		var spawn_x = global_position.x - 1000
		new_cloud.position = Vector2(spawn_x, spawn_y)
		get_tree().current_scene.add_child(new_cloud)
		
		# Keep this math clean and simple
		var base_wait = randf_range(0.5, 2.0 + cloud_density)
		$Timer.wait_time = base_wait * Weather.cloud_density_mult
