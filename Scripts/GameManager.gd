# GameManager.gd
extends Node

var coins: int = 0
var current_checkpoint_pos: Vector2

func collect_coin():
	coins += 1
	# You can emit a signal here if the UI needs to update a coin counter
	
func save_checkpoint(pos: Vector2):
	current_checkpoint_pos = pos

# This is where you can put Level Transition logic
func load_next_level(path: String):
	get_tree().change_scene_to_file(path)
