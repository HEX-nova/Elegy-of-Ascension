extends CanvasLayer

const ITEM_SCENE = preload("res://Scenes/item.tscn")

@onready var stats_comp = StatsComponent
@onready var list_container = $"Inventory/BG/scroll/unit"
@onready var detail_icon = $"Inventory/BG/Lowerhalf/VBoxContainer/HBoxContainer/Icon"
@onready var detail_data = $"Inventory/BG/Lowerhalf/VBoxContainer/HBoxContainer/Data"
@onready var detail_desc = $"Inventory/BG/Lowerhalf/VBoxContainer/Description"
@onready var button_use = $"Inventory/BG/Buttons/use"
@onready var button_discard = $"Inventory/BG/Buttons/discard"
@onready var button_cancel = $"Inventory/BG/Buttons/cancel"


var selected_item: ItemData = null

func _ready() -> void:
	visible = false
	update_stat_labels()
	_toggle_action_buttons(false)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Stats") or Input.is_action_just_pressed("Inventory"):
		toggle_menu()

func toggle_menu():
	visible = !visible
	get_tree().paused = visible
	if visible:
		update_stat_labels()
		_refresh_ui()

func update_stat_labels():
	if stats_comp == null: return
	var level_label = $"MenuRoot/Background/UpperStats/Name _ level/Level"
	level_label.text = str(stats_comp.level)
	var grid = $MenuRoot/Background/UpperStats/Stats
	grid.get_node("Attack/Value").text  = str(stats_comp.attack)
	grid.get_node("Defense/Value").text = str(stats_comp.defense)
	grid.get_node("Speed/Value").text   = str(stats_comp.move_speed)
	grid.get_node("Health/Value").text  = str(int(round(stats_comp.current_health))) + "/" + str(int(round(stats_comp.max_health)))
	grid.get_node("Atheer/Value").text  = str(int(round(stats_comp.current_atheer))) + "/" + str(int(round(stats_comp.max_atheer)))
	grid.get_node("Stamina/Value").text = str(int(round(stats_comp.current_stamina))) + "/" + str(int(round(stats_comp.max_stamina)))
	grid.get_node("Weight/Value").text  = str(stats_comp.weight)

func _select_item(item: ItemData):
	selected_item = item
	
	# Update Detail View
	detail_icon.texture = item.icon
	detail_desc.text = item.description
	
	var type_string = ItemData.Type.keys()[item.type]
	detail_data.text = "Name: %s\nType: %s\nValue: %d\nQty: %d" % [
		item.name, type_string, item.value, item.quantity
	]
	
	_toggle_action_buttons(true)
	
	# Dynamic button text
	if item.type == ItemData.Type.WEAPON:
		button_use.text = "Equip"
	else:
		button_use.text = "Use"

func _deselect():
	selected_item = null
	detail_icon.texture = null
	detail_data.text = "Select an item..."
	detail_desc.text = ""
	_toggle_action_buttons(false)

func _toggle_action_buttons(is_active: bool):
	if button_use: button_use.disabled = !is_active
	if button_discard: button_discard.disabled = !is_active

func _refresh_ui():
	if list_container == null:
		list_container = $"Inventory/BG/scroll/unit"
		if list_container == null: return
	
	for child in list_container.get_children():
		child.queue_free()
	
	for item in Inventory.inventory:
		# Create a clean Icon button
		var slot = Button.new()
		slot.icon = item.icon
		slot.expand_icon = true
		
		# Set a square size so it looks like a grid unit
		slot.custom_minimum_size = Vector2(64, 64) 
		
		# Optional: Tooltip so you see the name when hovering
		slot.tooltip_text = item.name
		
		# Connect the same selection logic
		slot.pressed.connect(_select_item.bind(item))
		
		list_container.add_child(slot)
	
	_deselect()

func _on_use_pressed():
	if selected_item:
		# The item decides what to do!
		var was_consumed = selected_item.use()
		
		if was_consumed:
			selected_item.quantity -= 1
			if selected_item.quantity <= 0:
				Inventory.inventory.erase(selected_item)
				_deselect()
		
		update_stat_labels()
		_refresh_ui()

func _on_discard_pressed():
	if selected_item:
		# 1. Spawn the item back into the world
		_spawn_item_in_world(selected_item)
		
		# 2. Remove from inventory array
		Inventory.inventory.erase(selected_item)
		
		# 3. Update UI
		print("Dropped: ", selected_item.name)
		_deselect()
		_refresh_ui()

func _on_cancel_pressed():
	_deselect()

func _spawn_item_in_world(data: ItemData):
	# Create the visual/physical node
	var new_item = ITEM_SCENE.instantiate()
	
	# Inject the data so it knows it's the 'Wooden Key' and not an apple
	new_item.item_data = data 
	
	# Get the player's current position
	# (Assuming you have a global reference to the player or they are in a 'Player' group)
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		# Drop it slightly offset so the player doesn't instantly pick it up again
		new_item.global_position = player.global_position + Vector2(20, 0)
		
		# Add it to the current level/world node
		# Don't add as child of Player! Add to the level.
		get_tree().current_scene.add_child(new_item)
