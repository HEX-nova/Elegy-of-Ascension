extends Area2D

var direction = Vector2.ZERO
var speed = 400.0

# Using a "setter" ensures the animation changes the MOMENT the variable is set
var element_type: int = 0:
	set(value):
		element_type = value
		_update_projectile_visual()

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D 

func _ready():
	# Final check when entering the world
	_update_projectile_visual()

func _update_projectile_visual():
	# If the node isn't ready yet, @onready hasn't fired, so anim is null.
	# We check for that to prevent a crash.
	if anim == null: return 
	
	var anim_name = str(element_type)
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	else:
		print("!!! PROJECTILE ERROR: Animation '", anim_name, "' not found in SpriteFrames!")

func _physics_process(delta):
	position += direction * speed * delta
func _on_body_entered(body):
	if body.is_in_group("Player"): return
	var stats = body.find_child("EnemyStatsComponent")
	if stats:
		stats.take_damage(StatsComponent.base_attack, element_type)
	
	queue_free()
