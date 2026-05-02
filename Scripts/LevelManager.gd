extends Node

# Key: location_id, Value: Node2D (The Central Hub)
var hub_registry = {}

# Register hubs as they enter the scene
func register_hub(location_id: String, hub_node: Node2D):
	hub_registry[location_id] = hub_node

func get_hub(location_id: String) -> Node2D:
	return hub_registry.get(location_id)

func teleport_player(target_pos: Vector2):
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.global_position = target_pos
		# You can add a screen fade-out/in here later!
