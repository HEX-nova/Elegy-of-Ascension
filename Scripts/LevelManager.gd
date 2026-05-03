extends Node

var central_shrine: Node2D = null

# Call this whenever you load a new level/scene
func scan_level_portals():
	central_shrine = null 
	
	# We grab everything you tagged with the "Portal" group
	var all_potential_hubs = get_tree().get_nodes_in_group("Portal")
	
	for node in all_potential_hubs:
		# Option A: Check if the node name contains "Shrine"
		if "Shrine" in node.name:
			central_shrine = node
			print("LevelManager: Found the Shrine by Name: ", node.name)
			break
			
		# Option B: Check if it has a specific variable unique to Shrines
		# (Like 'is_shrine' or 'shrine_id')
		if node.get("is_shrine") == true:
			central_shrine = node
			print("LevelManager: Found the Shrine by Property")
			break

func teleport_to_shrine():
	var player = get_tree().get_first_node_in_group("Player")
	
	if player and central_shrine:
		var target_pos = central_shrine.global_position + Vector2(0, -10) # Drop slightly above
		
		# 1. Create the sequence
		var tween = create_tween().set_parallel(false)
		
		# --- PHASE 1: Take Off ---
		# Disable movement so the player doesn't walk away mid-air
		player.set_physics_process(false) 
		tween.tween_property(player, "global_position", player.global_position + Vector2(0, -40), 0.4)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "scale", Vector2(0.2, 1.5), 0.2) # Stretch upward
		
		# --- PHASE 2: The "Flash" or Invisible Snap ---
		tween.tween_interval(0.5) # Brief pause at the peak
		tween.tween_callback(func(): player.global_position = target_pos)
		
		# --- PHASE 3: The Drop ---
		tween.tween_property(player, "scale", Vector2(1.0, 1.0), 0.1)
		tween.tween_property(player, "global_position", target_pos + Vector2(0, 10), 0.3)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			
		# Re-enable movement
		tween.tween_callback(func(): 
			player.set_physics_process(true)
			player.velocity = Vector2.ZERO
			print("Safe landing!")
		)
	else:
		print("Teleport failed.")

func transition_to_level(next_scene_path: String):
	get_tree().change_scene_to_file(next_scene_path)
	await get_tree().process_frame 
	scan_level_portals()
