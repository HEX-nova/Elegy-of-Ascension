# DamageNumbers.gd (AUTOLOAD)
extends Node

var number_scene = preload("res://Scenes/DamageNumber.tscn")

func display_number(value: String, pos: Vector2, color: Color = Color.WHITE):
	var number = number_scene.instantiate()
	
	# CRITICAL FIX: Set the text property of the Label!
	number.text = value 
	number.modulate = color
	
	get_tree().current_scene.add_child(number)
	
	var start_pos = pos + Vector2(0, -10)
	number.global_position = start_pos
	
	var target_pos = start_pos + Vector2(0, -30) # Fly upwards
	number.start_floating(target_pos)
