class_name Inventory
extends Node2D

@export var max_capacity: float = 50.0
var items_list: Array[ItemData] = []

# Calculated property to get current weight
func get_current_weight() -> float:
	var total = 0.0
	for item in items_list:
		total += (item.weight * item.quantity) # Multiply here!
	return total

func add_item(new_item: ItemData) -> bool:
	# 1. Check if we already have this item to "Stack" it
	for item in items_list:
		if item.name == new_item.name:
			item.quantity += 1 # Or += new_item.quantity
			print("Stacked: ", item.name, " now has ", item.quantity)
			return true
			
	# 2. If it's a brand new item, check weight and add it
	if get_current_weight() + new_item.weight <= max_capacity:
		items_list.append(new_item)
		return true
		
	return false

func remove_item(item: ItemData):
	items_list.erase(item)
