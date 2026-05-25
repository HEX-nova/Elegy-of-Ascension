extends ItemData
class_name WeaponItem

enum Stat {ATTACK, DEFENSE, HEALTH, ATHEER, STAMINA, SPEED}
@export var buff: float = 10.0
@export var stat: Stat = Stat.ATTACK

func use(actor: Node):
	var stat_map = {
		Stat.ATTACK: "attack",
		Stat.DEFENSE: "defense",
		Stat.HEALTH: "max_health",
		Stat.ATHEER: "max_atheer",
		Stat.STAMINA: "max_stamina",
		Stat.SPEED: "move_speed"
	}
	var stat_name = stat_map[stat]
	
	# Safely modify the specific actor's StatsComponent
	var stats = actor.get_node_or_null("StatsComponent")
	if stats:
		var current_value = stats.get(stat_name)
		stats.set(stat_name, current_value + buff)
	
	print("Weapon equipped! ", stat_name, " increased by ", buff)
	
	# Find the weapon slot *only* under this specific actor
	# Set 'recursive' to false if it's a direct child, or true if it's deeper down
	var weapon_slot = actor.find_child("Weapon", true, false) 
	if weapon_slot:
		weapon_slot.weapon = self
	else:
		push_error("Equip failed: No 'Weapon' slot found on " + actor.name)
		
	return false
