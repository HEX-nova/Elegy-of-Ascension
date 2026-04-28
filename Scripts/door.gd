extends StaticBody2D

@export var required_key_name: String = "Wooden key"
@onready var interaction_area = $Interaction
var is_locked = true

func _ready():
	interaction_area.body_entered.connect(_on_player_entered)

func _on_player_entered(body):
	# Only try to open if it's the player AND the door is still locked
	if body.is_in_group("Player") and is_locked:
		_try_open_door()

func _try_open_door():
	# We check the inventory directly right here
	var found_it = false
	for item in Inventory.inventory:
		if item.name == required_key_name:
			found_it = true
			break # Stop looking, we found it!
	
	if found_it:
		print("The Viridian key turns in the lock.")
		_open_animation()
	else:
		print("Locked. You need the: ", required_key_name)

func _open_animation():
	is_locked = false
	# Disable collision so the player can walk through
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5) # Fade out
	tween.tween_callback(queue_free) # Delete the door after fading
	
	print("Door Opened.")
