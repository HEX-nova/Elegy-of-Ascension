extends Area2D

@export var speed: float = 500.0
@export var damage: float = 15.0
var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	# Move in a straight line
	position += direction * speed * delta

func destroy():
	# You can add a particle effect here later!
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	# If we hit an enemy (Layer 5)
	if body.has_method("take_damage"):
		body.take_damage(25)
	# No matter what we hit (Wall or Enemy), the icicle breaks
	destroy()
