extends StaticBody2D

enum PortType { BASIC, CENTRAL }

@export_group("Identity")
@export var type: PortType = PortType.BASIC
@export var location_id: String = "Region_1"

func _ready():
	# If I am a Hub, I register myself so others can find me instantly
	if type == PortType.CENTRAL:
		LevelManager.register_hub(location_id, self)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if type == PortType.BASIC:
			var hub = LevelManager.get_hub(location_id)
			if hub:
				LevelManager.teleport_player(hub.global_position)
		else:
			# Logic for opening the Hub Menu
			print("Opening Menu for: ", location_id)
