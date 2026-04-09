extends CharacterBody2D

@export var speed : float = 50.0
var direction : int = -1
@onready var sprite = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("default")

func _physics_process(delta: float) -> void:
	if speed or direction == null : 
		pass
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Walk logic
	if is_on_floor():
		velocity.x = speed * direction
	# THE FIX: Wall bounce logic
	if is_on_wall():
		direction *= -1
		# Force the velocity change IMMEDIATELY so it moves away next frame
		velocity.x = speed * direction
		sprite.flip_h = (direction == 1)
	move_and_slide()
