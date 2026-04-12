extends Control

# Use the % Unique Name or correct paths to your bars
@onready var health_bar = $BarsContainer/HealthBar
@onready var atheer_bar = $BarsContainer/ManaBar
@onready var stamina_bar = $BarsContainer/StaminaBar
@onready var exp_bar = $BarsContainer/ExpBar
@onready var level = $BarsContainer/Label

func _ready():
	# Connect the UI to the Manager's signal
	StatsComponent.stats_changed.connect(update_bars)
	update_bars()

func update_bars():
	# Sync Max Values
	health_bar.max_value = StatsComponent.max_health
	atheer_bar.max_value = StatsComponent.max_atheer
	stamina_bar.max_value = StatsComponent.max_stamina
	exp_bar.max_value = StatsComponent.max_exp
	# Sync Current Values
	health_bar.value = StatsComponent.current_health
	atheer_bar.value = StatsComponent.current_atheer
	stamina_bar.value = StatsComponent.current_stamina
	exp_bar.value = StatsComponent.current_exp
	#Sync Level display
	level.text = str(StatsComponent.level)
