extends Area2D

var direction = Vector2.ZERO
var speed = 400.0
var damage_amount = round(StatsComponent.base_attack)

# Setter handles visual updates automatically
var element_type: int = 0:
	set(value):
		element_type = value
		_update_projectile_visual()

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D 

func _ready():
	# Only need to ensure visuals match the passed element_type
	_update_projectile_visual()

func _update_projectile_visual():
	if anim == null: return 
	
	var anim_name = str(element_type)
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	else:
		print("!!! PROJECTILE ERROR: Animation '", anim_name, "' not found!")

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	# Ignore the player who shot it
	if body.is_in_group("Player"): 
		return
		
	# Look for the specific stats component on the Thornspitter/Enemy
	var enemy_stats = body.find_child("EnemyStatsComponent")
	if enemy_stats and enemy_stats.has_method("take_damage"):
		# We use the projectile's stored element and the damage it was given
		enemy_stats.take_damage(damage_amount, element_type)
		queue_free() # Destroy on hit
	elif body is TileMap: # Optional: destroy if hits a wall
		queue_free()
