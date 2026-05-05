extends Control

@onready var start = $CanvasLayer/VBoxContainer/StartButton
@onready var load = $CanvasLayer/VBoxContainer/LoadButton
@onready var exit = $CanvasLayer/VBoxContainer/ExitButton

@export_file("*.tscn") var first_level_path: String

func _ready() -> void:
	start.pressed.connect(_on_start_button_pressed)
	load.pressed.connect(_on_load_button_pressed)
	exit.pressed.connect(_on_exit_button_pressed)

func _on_start_button_pressed():
	get_tree().change_scene_to_file(first_level_path)

func _on_load_button_pressed():
	print("Searching for save files in user://...")

func _on_exit_button_pressed():
	get_tree().quit()
