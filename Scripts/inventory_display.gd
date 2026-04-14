extends CanvasLayer

@onready var control_root = $Control
var is_open = false
@onready var list_container = $Control/ScrollContainer/VBoxContainer
@onready var display = $TextureRect
@export var slot_scene : PackedScene = preload("res://Scenes/inventory_slot.tscn")

func _ready():
	# This will now hide the Control AND everything inside it (BG + List)
	control_root.hide()
	display.hide()

func refresh_display():
	# 1. Clear existing slots
	for child in list_container.get_children():
		child.queue_free()
		
	# 2. Try to find the player
	var player = get_tree().get_first_node_in_group("Player")
	
	# THE GUARD: If player is null, stop here and don't crash!
	if player == null:
		print("UI Error: No node found in 'Player' group!")
		return
		
	# 3. Double check if the inventory node exists on that player
	if not player.get("inventory"):
		print("UI Error: Player found, but has no inventory node!")
		return

	# 4. Now it's safe to loop
	for item in player.inventory.items_list:
		var slot = slot_scene.instantiate()
		list_container.add_child(slot)
		slot.setup(item)

func _input(event: InputEvent) -> void:
	# Use the Capital "I" Input class here
	if Input.is_action_just_pressed("inventory"): 
		toggle_inventory()

func toggle_inventory():
	is_open = !is_open
	
	# This flips the visibility of the Master Container
	control_root.visible = is_open
	display.visible = is_open
	
	get_tree().paused = is_open
	
	if is_open:
		refresh_display()
