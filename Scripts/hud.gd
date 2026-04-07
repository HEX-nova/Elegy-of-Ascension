extends CanvasLayer

@onready var coin_label = $"UI container/Counter/Label"

func _ready() -> void:
	# Connect to the Manager's signal we made earlier
	StatsComponent.stats_changed.connect(update_ui)
	update_ui() # Set initial values

func update_ui():
	# Update the text to match the Manager's coin count
	coin_label.text = str(GameManager.coins)
