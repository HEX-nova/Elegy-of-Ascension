extends Control

# Use the % Unique Name or correct paths to your bars
@onready var health_bar = $BarsContainer/HealthBar
@onready var mana_bar = $BarsContainer/ManaBar
@onready var stamina_bar = $BarsContainer/StaminaBar
@onready var exp_bar = $BarsContainer/ExpBar

func _ready():
	# Connect the UI to the Manager's signal
	GameManager.stats_changed.connect(update_bars)
	update_bars()

func update_bars():
	# Sync Max Values
	health_bar.max_value = GameManager.max_health
	mana_bar.max_value = GameManager.max_mana
	stamina_bar.max_value = GameManager.max_stamina
	exp_bar.max_value = GameManager.max_xp
	
	# Sync Current Values
	health_bar.value = GameManager.health
	mana_bar.value = GameManager.mana
	stamina_bar.value = GameManager.stamina
	exp_bar.value = GameManager.xp
