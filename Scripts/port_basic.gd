extends StaticBody2D # Or Area2D

enum PortType { BASIC, CENTRAL }
@export var type: PortType = PortType.BASIC
@export var leads_to_new_scene: bool = false
@export var target_scene_path: String = ""

func _ready():
	# Optional: Make sure they are actually in the group
	add_to_group("Portal")
	# Trigger a scan if this is the first portal loading
	if LevelManager.central_shrine == null:
		LevelManager.scan_level_portals()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if leads_to_new_scene and type == PortType.BASIC:
			LevelManager.transition_to_level("res://Scenes/" + target_scene_path)
		if type == PortType.BASIC and !leads_to_new_scene:
			LevelManager.teleport_to_shrine()
		else:
			print("Slime is at the Central Hub.")
