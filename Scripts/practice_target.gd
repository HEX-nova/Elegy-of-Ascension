extends CharacterBody2D

@onready var stats_comp = $EnemyStatsComponent
@onready var sprite = $AnimatedSprite2D

func _ready():
	# Connect the Component's signals to local functions
	stats_comp.on_hit.connect(_on_stats_hit)
	stats_comp.on_death_started.connect(_on_stats_die)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

# This is called by the component now!
func take_damage(amount, element): # Add 'element' here!
	# Now pass both to the component
	stats_comp.take_damage(amount, element)

func _on_stats_hit():
	sprite.play("Hit")
	# Return to idle after a moment
	await get_tree().create_timer(0.2).timeout
	if stats_comp.current_hp > 0:
		sprite.play("Idle")

func _on_stats_die():
	# You can add a death effect here (particles, etc)
	print("Dummy is de-rezzed!")
