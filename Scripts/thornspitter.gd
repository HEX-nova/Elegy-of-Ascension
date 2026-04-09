extends StaticBody2D

# --- SETTINGS ---
@export var fire_rate: float = 1.0
@export var thorn_speed: float = 450.0
@export var thorn_scene: PackedScene = preload("res://Scenes/thorn.tscn") # Make sure to save your Thorn scene here!

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var stats = $EnemyStatsComponent

var target: Node2D = null
var can_fire: bool = true

func _ready() -> void:
	add_to_group("Enemy")
	sprite.play("Idle")

func _process(_delta: float) -> void:
	if target:
		# Face the player (Flip based on X position)
		sprite.flip_h = (target.global_position.x < global_position.x)
		
		if can_fire:
			_shoot_thorn()

func _shoot_thorn():
	can_fire = false
	
	# 1. Play Attack Animation
	if sprite.sprite_frames.has_animation("Attack"):
		sprite.play("Attack")
	
	# 2. Spawn the Thorn
	var thorn = thorn_scene.instantiate()
	get_tree().current_scene.add_child(thorn)
	thorn.scale = Vector2(0.3, 0.3)
	# Position it at the Spitter's mouth/center
	thorn.global_position = global_position
	
	# Calculate direction toward Tun
	var dir = (target.global_position - global_position).normalized()
	
	# Setup Thorn (Assuming your Thorn script has these variables)
	if thorn.has_method("setup"):
		thorn.setup(dir, thorn_speed, stats.attack)
	
	# 3. Cooldown
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
	
	if target:
		sprite.play("Idle") # Go back to idle/aiming

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target = body
		print("Thornspitter sighted Tun!")

func _on_detection_area_body_exited(body: Node2D) -> void:
		if body == target:
			target = null
		sprite.play("Idle")
