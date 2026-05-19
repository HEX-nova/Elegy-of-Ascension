extends Area2D

@export var weapon : WeaponItem
@onready var sprite : Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.texture = weapon.icon

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		var stats = body.find_child("EnemyStatsComponent")
		stats.take_damage(StatsComponent.attack, StatsComponent.element_type)
	
	if body.collision_layer & 128:
		parry_object(body)

func _on_area_entered(area: Area2D) -> void:
	# Also check Areas (for projectiles that are Area2Ds)
	if area.collision_layer & 128:
		parry_object(area)

func parry_object(target: Node2D):
	# 1. Visual/Audio Feedback
	print("Parried: ", target.name)
	# spawn_parry_spark() # If you have a particle effect
	
	# 2. Destroy the object
	if target.has_method("die"):
		target.die() # Use the object's own cleanup if it exists
	else:
		target.queue_free() # Hard delete
