extends Area2D

@export var item_data: ItemData 

func _ready():
	if item_data and item_data.icon:
		$Sprite2D.texture = item_data.icon

func collect(player):
	
	if item_data:
		player.collect_item(item_data)
		print("Collected: ", item_data.name)
		queue_free() 
	else:
		print("Warning: This item has no ItemData assigned!")

func _on_body_entered(body):
	if body.is_in_group("Player"): 
		collect(body)
