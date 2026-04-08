extends Node2D
class_name EnemyStatsComponent

# Add these signals at the top
signal on_hit
signal on_death_started
@onready var health_bar = $HealthBar

@export_group("Identity")
@export var element_type: Elements.Type = Elements.Type.NHLM
@export var enemy_name: String = "Minion"

@export_group("Base Stats")
@export var base_hp: float = 200.0
@export var base_atk: float = 15.0
@export var base_def: float = 5.0
@export var xp_reward: float = 25.0

var current_hp: float
var max_hp: float
var attack: float
var defense: float

func _ready():
	await get_tree().process_frame
	sync_stats()
	current_hp = max_hp
	
	# Initialize the bar
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		health_bar.hide()

func sync_stats():
	var p_level = StatsComponent.level
	var growth = 1 * (p_level - 1) 
	var hp_mod = Elements.get_stat(2, element_type)
	var atk_mod = Elements.get_stat(0, element_type)
	var def_mod = Elements.get_stat(1, element_type)
	
	max_hp = base_hp + growth * hp_mod
	attack = base_atk + growth + atk_mod
	defense = base_def + growth + def_mod

func take_damage(incoming_atk: float, attacker_element: int):
	var multiplier = Elements.get_multiplier(attacker_element, element_type)
	var damage_after_def = (incoming_atk * incoming_atk) / (incoming_atk + defense)
	var final_dmg = damage_after_def * multiplier
	
	current_hp -= round(final_dmg)
	# Update the Bar
	if health_bar:
		health_bar.show()
		health_bar.value = current_hp
		
		# Optional: Make it "Shake" or flash when hit
		var tween = create_tween()
		tween.tween_property(health_bar, "modulate", Color(2, 2, 2, 1), 0.1) # Flash white
		tween.tween_property(health_bar, "modulate", Color(1, 1, 1, 1), 0.1)
	
	var display_color = Color.WHITE
	if multiplier > 1.2: display_color = Color.RED
	elif multiplier < 0.8 and multiplier > 0: display_color = Color.YELLOW
	elif multiplier == 0: display_color = Color.GRAY
	DamageNumberDisplay.display_number(str(-1 * round(final_dmg)), global_position, display_color)
	
	# NEW: Tell the parent we got hit!
	on_hit.emit()
	
	if current_hp <= 0:
		_on_death()

func _on_death():
	StatsComponent.current_exp += xp_reward * (1.0 + (StatsComponent.level * 0.1))
	# NEW: Tell the parent to play its death animation before we delete it
	on_death_started.emit()
	# Give it a tiny bit of time for the animation before queue_free
	await get_tree().create_timer(0.1).timeout
	get_parent().queue_free()
