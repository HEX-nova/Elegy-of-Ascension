extends Area2D

enum PortType { BASIC, CENTRAL }

@export_group("Identity")
@export var type: PortType = PortType.BASIC
@export var location_id: String = "Region_1" # e.g., 'Atheerium_Core'
@export var portal_id: String = "North_Gate"  # Unique name for this portal

@export_group("Navigation")
@export var target_scene: PackedScene # Only used if moving between levels

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		match type:
			PortType.BASIC:
				_teleport_to_hub()
			PortType.CENTRAL:
				_open_hub_menu()

func _teleport_to_hub():
	# Logic: Look for the node in the current scene tagged as 'CENTRAL'
	# and belonging to the same 'location_id'
	var central_hub = _find_central_hub()
	if central_hub:
		get_tree().current_scene.player.global_position = central_hub.global_position
		print("Returning to ", location_id, " Hub.")

func _open_hub_menu():
	# Here you would trigger a UI menu that lists all 'unlocked' portals
	# for this Location ID or other Central Hubs.
	print("Welcome to Central Hub: ", location_id)
	# UI.show_teleport_menu(location_id)

func _find_central_hub():
	# Helper to find the hub in the scene
	for node in get_tree().get_nodes_in_group("Portals"):
		if node.type == PortType.CENTRAL and node.location_id == location_id:
			return node
	return null
