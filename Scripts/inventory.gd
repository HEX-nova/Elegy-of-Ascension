extends Node

var inventory: Array[ItemData] = []
var recieved = false
@onready var list_container # Where your UI items go
@onready var InventoryUI

func _ready():
	InventoryUI = get_tree().get_first_node_in_group("InventoryUI")

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
