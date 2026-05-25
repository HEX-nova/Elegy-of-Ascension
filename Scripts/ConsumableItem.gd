extends ItemData
class_name ConsumableItem

enum Stat {ATTACK, DEFENSE, HEALTH, ATHEER, STAMINA, SPEED}

@export var affected_stat: Stat = Stat.HEALTH
@export var boost_value: int = 20
@export var boost_duration: float = 60.0

func use(player:Node):
	# 1. Map the Enum to the actual variable names in your StatsComponent
	var stat_map = {
		Stat.ATTACK: "attack",
		Stat.DEFENSE: "defense",
		Stat.HEALTH: "current_health",
		Stat.ATHEER: "current_atheer",
		Stat.STAMINA: "current_stamina",
		Stat.SPEED: "move_speed"
	}
	
	var stat_name = stat_map[affected_stat]
	
	# 2. Check if it's a "Permanent" restore (Health/Atheer/Stamina)
	if affected_stat in [Stat.HEALTH, Stat.ATHEER, Stat.STAMINA]:
		var current_val = StatsComponent.get(stat_name)
		# Find the max version (e.g., "max_health")
		var max_name = stat_name.replace("current_", "max_")
		var max_val = StatsComponent.get(max_name)
		
		StatsComponent.set(stat_name, min(current_val + boost_value, max_val))
		print("Restored ", boost_value, " to ", stat_name)
	
	# 3. Check if it's a "Temporary" buff (Attack/Defense/Speed)
	else:
		_apply_temp_buff(stat_name)
		
	return true # Item is consumed

func _apply_temp_buff(stat_name: String):
	# Increase the stat
	var original_val = StatsComponent.get(stat_name)
	StatsComponent.set(stat_name, original_val + boost_value)
	print("Buffed ", stat_name, " by ", boost_value, " for ", boost_duration, "s")
	
	# Wait for the duration, then take it back
	# We use a SceneTreeTimer so it runs even if this resource is "erased"
	var timer = Engine.get_main_loop().root.get_tree().create_timer(boost_duration)
	await timer.timeout
	
	var current_val = StatsComponent.get(stat_name)
	StatsComponent.set(stat_name, current_val - boost_value)
	print("Buff expired for ", stat_name)
