extends Area2D

# 1. Add a setter to the weapon variable
@export var weapon : WeaponItem:
	set(new_weapon):
		weapon = new_weapon
		update_weapon_visuals() # This triggers automatically when self is assigned!

@onready var sprite : Sprite2D = $Sprite2D

func _ready() -> void:
	# Keep this here so if the player spawns with a weapon, it shows up
	update_weapon_visuals()

# 2. Move the visual updating logic into its own function
func update_weapon_visuals():
	# If the sprite node isn't ready yet (safety check during game bootup), wait
	if not is_node_ready():
		await ready
		
	if weapon == null:
		sprite.texture = null # Clear the sprite if unequipped
	else:
		sprite.texture = weapon.icon # Note: ItemData has 'icon', which WeaponItem inherits!

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		var stats = body.find_child("EnemyStatsComponent")
		# Pro-tip: Make sure StatsComponent is accessible here. 
		# If StatsComponent is a child node of the player, use get_parent().StatsComponent.attack
		stats.take_damage(StatsComponent.attack, StatsComponent.element_type)
	
	if body.collision_layer & 128:
		parry_object(body)

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer & 128:
		parry_object(area)

func parry_object(target: Node2D):
	print("Parried: ", target.name)
	if target.has_method("die"):
		target.die()
	else:
		target.queue_free()
