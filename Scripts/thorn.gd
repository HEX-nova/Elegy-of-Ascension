extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 0.0
var damage: float = 0.0
var nature = 1

func setup(dir: Vector2, spd: float, dmg: float):
	direction = dir
	speed = spd
	damage = dmg
	# Rotate the thorn to face where it's flying
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

# Cleanup if it misses and flies off-screen
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	print("Thorn touched: ", body.name) # See what it's hitting
	if body.is_in_group("Player"):
		StatsComponent.take_damage(damage, nature)
		queue_free()
