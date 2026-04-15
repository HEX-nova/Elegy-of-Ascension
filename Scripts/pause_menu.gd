extends CanvasLayer

@onready var stats_comp = StatsComponent
@onready var list_container = $"Inventory/BG/scroll/unit"

func _ready() -> void:
	visible = false
	update_stat_labels()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Stats") or Input.is_action_just_pressed("Inventory"):
		toggle_menu()
		for item in Inventory.inventory:
			print(item.name)

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

func _refresh_ui():
	# 1. THE NULL GUARD
	if list_container == null:
		# Try to find it again just in case it was a timing issue
		list_container = $"Inventory/BG/scroll/unit"
		if list_container == null:
			return # If still null, stop here to prevent the crash
	
	# 2. Clear old icons
	for child in list_container.get_children():
		child.queue_free()
	
	# 3. Redraw (only if you have items)
	for item in Inventory.inventory:
		var label = Label.new()
		label.text = item.name + " (×" + str(item.quantity) + ")"
		label.add_theme_color_override("font_color", Color.WHITE)
		var icon = TextureRect.new()
		icon.texture = item.icon
		var slot = HBoxContainer.new()
		slot.add_child(icon)
		slot.add_child(label)
		list_container.add_child(slot)
