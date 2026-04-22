extends ItemData
class_name WeaponItem

enum Stat {ATTACK, DEFENSE, HEALTH, ATHEER, STAMINA, SPEED}
@export var buff: float = 10.0
@export var stat: Stat = Stat.ATTACK

func use():
	var stat_map = {
		Stat.ATTACK: "attack",
		Stat.DEFENSE: "defense",
		Stat.HEALTH: "max_health",
		Stat.ATHEER: "max_atheer",
		Stat.STAMINA: "max_stamina",
		Stat.SPEED: "move_speed"
	}
	
	var stat_name = stat_map[stat]
	var current_value = StatsComponent.get(stat_name)
	
	# FIX: Use the set method correctly
	StatsComponent.set(stat_name, current_value + buff)
	
	print("Weapon equipped! ", stat_name, " increased by ", buff)
	
	# CRITICAL: Return false so the item isn't deleted from inventory!
	return false
