extends CanvasLayer

var inventory: Array[ItemData] = []
var recieved = false
@onready var list_container = $"BG/the scroll page/the item unit" # Where your UI items go

func _ready():
	self.visible = false # Start hidden

func _process(_delta): if Input.is_action_just_pressed("ui_accept"): print(Inventory.inventory)

func _input(event):
	if event is InputEventMouseMotion: return 
	if event.is_action_pressed("Inventory"):
		get_tree().paused = !get_tree().paused # Toggle the global pause
		self.visible = get_tree().paused       # Sync visibility to pause state
		print("Game Paused: ", get_tree().paused)
		if self.visible:
			print("--- Inventory Open ---")
			# RESTORED: Explicit check for empty state
			if inventory.is_empty():
				print("The inventory is currently empty!")
			else:
				for item in inventory:
					print(item.name + " ×" + str(item.quantity))
		else:
			print("--- Inventory Closed ---")

func add_to_inventory(data: ItemData):
	if data == null:
		print("!!! ERROR: Receiving Null Data !!!")
		return
	
	print("Adding: ", data.name, " (Value: ", data.value, ")") # DEBUG LINE
	
	var found = false
	for item in inventory:
		if item.name == data.name:
			item.quantity += data.quantity
			found = true
			print("Stacked: ", item.name, " total: ", item.quantity)
			break
			
	if not found:
		inventory.append(data)
		print("New item added to array. Size: ", inventory.size())

	recieved = true
	_refresh_ui()

'''func _refresh_ui():
	# 1. THE NULL GUARD
	if list_container == null:
		# Try to find it again just in case it was a timing issue
		list_container = get_node_or_null("BG/the scroll page/the item unit")
		if list_container == null:
			return # If still null, stop here to prevent the crash
	
	# 2. Clear old icons
	for child in list_container.get_children():
		child.queue_free()
	
	# 3. Redraw (only if you have items)
	for item in inventory:
		var label = Label.new()
		label.text = item.name + " (×" + str(item.quantity) + ")"
		label.add_theme_color_override("font_color", Color.WHITE)
		var icon = TextureRect.new()
		icon.texture = item.icon
		var slot = HBoxContainer.new()
		slot.add_child(icon)
		slot.add_child(label)
		list_container.add_child(slot)'''

func _refresh_ui():
	# 1. THE AGGRESSIVE SEARCH
	# Since it's an Autoload, we search relative to 'self' (the root of Inventory.tscn)
	var list = get_node_or_null("BG/the scroll page/the item unit")
	
	if list == null:
		print("!!! UI CRASH: I can't find 'the item unit' !!!")
		print("Current path check: ", get_path())
		return # Stop here to prevent the 'get_children' crash
	
	# 2. Clear old children safely
	for child in list.get_children():
		child.queue_free()
	
	# 3. Redraw
	for item in inventory:
		var slot = HBoxContainer.new()
		var label = Label.new()
		
		# Set text and ensure visibility
		label.text = str(item.name) + " (x" + str(item.quantity) + ")"
		label.add_theme_color_override("font_color", Color.WHITE)
		
		slot.add_child(label)
		list.add_child(slot)
