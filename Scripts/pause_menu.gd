extends CanvasLayer

@onready var stats_comp = StatsComponent
func _ready() -> void:
	visible = false
	update_stat_labels()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Stats"):
		toggle_menu()

func toggle_menu():
	visible = !visible
	get_tree().paused = visible
	if visible:
		update_stat_labels()

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
