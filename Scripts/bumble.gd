extends StaticBody2D

# --- MOVEMENT SETTINGS ---
@export var jitter_radius: float = 20.0   # How far it can "twitch" from its base
@export var jitter_speed: float = 8.0    # How fast it snaps to new spots
@export var chase_speed: float = 140.0 
@export var return_speed: float = 80.0

var base_position: Vector2   # The "Anchor" (moves toward player or home)
var home_position: Vector2   # The original spawn point
var jitter_offset: Vector2 = Vector2.ZERO
var target: Node2D = null

func _ready() -> void:
	home_position = global_position
	base_position = global_position
	add_to_group("Enemy")
	_update_jitter()

func _physics_process(delta: float) -> void:
	# 1. Update the Anchor (Base Position)
	if target == null:
		if base_position.distance_to(home_position) > 2.0:
			base_position = base_position.move_toward(home_position, return_speed * delta)
	else:
		base_position = base_position.move_toward(target.global_position, chase_speed * delta)
		$AnimatedSprite2D.flip_h = (target.global_position.x < global_position.x)

	# 2. Update the Jitter (The "Random" feel)
	# We lerp the jitter_offset toward a random point, then apply it to base_position
	if randf() < 0.05: # 5% chance every frame to pick a new random "twitch" direction
		_update_jitter()
	
	# Smoothly move toward the jitter target
	var final_target = base_position + jitter_offset
	global_position = global_position.lerp(final_target, jitter_speed * delta)

func _update_jitter():
	# Pick a random point inside a circle
	var angle = randf() * TAU
	var distance = randf() * jitter_radius
	jitter_offset = Vector2(cos(angle), sin(angle)) * distance

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") :
		target = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") :
		target = null
