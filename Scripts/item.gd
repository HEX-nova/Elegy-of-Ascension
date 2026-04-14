extends Area2D

@export var item_data: ItemData 

func _ready():
	if item_data and item_data.icon:
		$Sprite2D.texture = item_data.icon

func collect():
	if item_data:
		Inventory.add_to_inventory(item_data)
		print("Collected: ", item_data.name)
		if Inventory.recieved == true:
			queue_free() 
			Inventory.recieved = false
	else:
		print("Warning: This item has no ItemData assigned!")

func _on_body_entered(body):
	if body.is_in_group("Player"): 
		collect()
