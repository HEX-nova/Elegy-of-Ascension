extends Node
class_name Stats

# --- Vitals ---
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var max_atheer: float = 100.0

@onready var current_health: float = max_health
@onready var current_stamina: float = max_stamina
@onready var current_atheer: float = max_atheer

# --- THE FIX: The Setter ---
# Whenever you change this in the Inspector, sync_with_matrix() fires automatically!
@export var element_type: Elements.Type = Elements.Type.CRYO:
	set(value):
		element_type = value
		if is_inside_tree(): # Only sync if the node is actually in the game
			sync_with_matrix()

@export var level: int = 1:
	set(value):
		level = value
		if is_inside_tree():
			sync_with_matrix()

@export var can_take_damage: bool = true

# Calculated Values
var base_attack: float = 10.0
var attack: float
var base_defense: float = 10.0
var defense: float
var attack_speed_mult: float = 1.0
var move_speed_mult: float = 1.0
var weight: float = 1.0
var move_speed: float = 200.0

# Progression
@export var current_exp: int = 0
var max_exp: int = 100

signal stats_changed

func _ready():
	sync_with_matrix()
	current_health = max_health
	stats_changed.emit()

func sync_with_matrix():
	# 1. Pull Multipliers
	move_speed_mult = Elements.get_stat(6, element_type)
	attack_speed_mult = Elements.get_stat(5, element_type)
	weight = Elements.get_stat(7, element_type)
	
	# 2. Level Scaling
	defense = base_defense + (Elements.get_stat(1, element_type) * level)
	attack = base_attack + (Elements.get_stat(0, element_type) * level)
	move_speed = 200.0 * move_speed_mult
	
	# 3. Max Vitals
	max_health = 100.0 + (Elements.get_stat(2, element_type) * level)
	max_atheer = 100.0 + (Elements.get_stat(3, element_type) * level)
	max_stamina = 100.0 + (Elements.get_stat(4, element_type) * level)
	
	stats_changed.emit()
	# print("STATS SYNCED: ", Elements.Type.keys()[element_type], " | ATK: ", base_attack)

func _physics_process(delta: float) -> void:
	max_exp = 100 + ((level - 1) * 150)
	if current_exp >= max_exp:
		level_up()
	_handle_regeneration(delta)
	if Input.is_action_just_pressed("ui_x_key"): # Make sure "ui_x_key" is mapped to X in Input Map
		cycle_element()

func _handle_regeneration(delta):
	if current_health < max_health:
		current_health = move_toward(current_health, max_health, Elements.get_stat(8, element_type) * 2 * delta)
	if current_atheer < max_atheer:
		current_atheer = move_toward(current_atheer, max_atheer, Elements.get_stat(9, element_type) * 5 * delta)
	stats_changed.emit()

func take_damage(incoming_atk: float, attacker_element: int):
	var multiplier = Elements.get_multiplier(attacker_element, element_type)
	var damage_after_defense = (incoming_atk * incoming_atk) / (incoming_atk + defense)
	var final_damage = snapped(damage_after_defense * multiplier, 0.1)
	
	if can_take_damage:
		current_health -= round(final_damage)
		
		# SAFE POSITION CHECK: Find the root node (Tun or Enemy)
		var target_node = get_tree().get_first_node_in_group("Player")
		var pos = target_node.global_position + Vector2(0, -20)
		
		var display_color = Color.WHITE
		if multiplier > 1.2: display_color = Color.ORANGE_RED
		elif multiplier < 0.8: display_color = Color.GRAY
		DamageNumberDisplay.display_number(str(-1 * round(final_damage)), pos, display_color)
		target_node.play_damaged_effect()
		start_invulnerability()
		if current_health <= 0:
			die()
		stats_changed.emit()

func start_invulnerability():
	can_take_damage = false
	# Flash the sprite or wait 1 second
	await get_tree().create_timer(1.0).timeout 
	can_take_damage = true

func level_up():
	level += 1
	current_exp -= max_exp
	# sync_with_matrix() is called automatically by the level setter!
	
	var player = get_tree().get_first_node_in_group("Player")
	if player: player.is_leveling = true

func die():
	# 1. Reset health immediately so we don't "die" twice in one frame
	current_health = max_health
	
	# 2. Find the player root safely
	var player_node = null
	
	# Check if 'owner' exists first!
	if is_instance_valid(owner):
		player_node = owner
	else:
		# Fallback: find anyone in the Player group
		player_node = get_tree().get_first_node_in_group("Player")

	# 3. Only proceed if we actually found a player instance
	if is_instance_valid(player_node):
		if player_node.is_in_group("Player"):
			var spawn = get_tree().current_scene.find_child("SpawnPoint", true, false)
			if spawn:
				# set_deferred is non-negotiable here to prevent physics crashes
				player_node.set_deferred("global_position", spawn.global_position)
				# Reset physics so you don't keep sliding after respawn
				if "velocity" in player_node:
					player_node.set_deferred("velocity", Vector2.ZERO)
				print("RESPAWN: Player moved to SpawnPoint.")
			else:
				# If no spawnpoint, just reload
				get_tree().call_deferred("reload_current_scene")
	else:
		# If the player is somehow already gone, just reload the level
		get_tree().call_deferred("reload_current_scene")
	
	stats_changed.emit()

func cycle_element():
	# Use the actual count of your Enum keys to avoid out-of-bounds crashes
	var element_count = Elements.Type.size() 
	
	# Use the Node's element_type, not the Global class if possible
	var current = element_type 
	var next = (current + 1) % element_count
	
	element_type = next # This triggers the @export setter and syncs stats!
	
	var element_name = Elements.Type.keys()[next]
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		DamageNumberDisplay.display_number(element_name, player.global_position, Color.CYAN)
	print("TUN SWITCHED TO: ", element_name)

func take_fixed_damage(amount):
	current_health -= amount
	var target_node = get_tree().get_first_node_in_group("Player")
	var pos = target_node.global_position + Vector2(0, -20)
	DamageNumberDisplay.display_number(str(-1 * round(amount)), pos, Color.WHITE)
	target_node.play_damaged_effect()
	start_invulnerability()
	if current_health <= 0:
		die()
	stats_changed.emit()
