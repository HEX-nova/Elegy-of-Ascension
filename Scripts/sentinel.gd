extends StaticBody2D

@onready var stats_comp = $EnemyStatsComponent
@onready var laser_line = $Line2D
@onready var ray = $RayCast2D
@onready var sprite = $AnimatedSprite2D
@onready var muzzle = $LaserMuzzle 

var player = null
var charge_timer = 0.0
const CHARGE_TIME_LIMIT = 1.2
var can_fire_burst = true 

func _ready():
	laser_line.visible = false
	muzzle.visible = false
	laser_line.z_index = 10 
	muzzle.z_index = 11
	ray.enabled = true
	# Force the Line2D to use Global space if it's acting weird
	laser_line.top_level = true 

func _physics_process(delta: float) -> void:
	if player == null:
		_handle_passive_state()
		return
	_handle_attack_state(delta)

func _handle_attack_state(delta):
	sprite.play("Angry")
	charge_timer += delta
	
	# We use muzzle.global_position as the "EYE" of the sentinel
	var start_point = muzzle.global_position
	var player_pos = player.global_position
	
	# 1. Aiming the Raycast
	ray.target_position = ray.to_local(player_pos)
	ray.force_raycast_update()
	
	# 2. Muzzle Rotation
	muzzle.visible = true
	muzzle.global_rotation = (player_pos - start_point).angle()
	
	# 3. Laser Points (Using Global Coordinates)
	laser_line.visible = true
	laser_line.clear_points()
	laser_line.add_point(start_point) 
	
	# Determine where the laser ends
	var end_point = player_pos
	if ray.is_colliding():
		end_point = ray.get_collision_point()
	
	laser_line.add_point(end_point)

	# 4. Visual States & Damage
	if charge_timer < CHARGE_TIME_LIMIT:
		# CHARGING PHASE
		var pulse = randf_range(0.8, 1.1)
		laser_line.width = 4.0 * pulse
		laser_line.modulate.a = 0.3
		muzzle.scale = Vector2(0.5, 0.5) * pulse
		muzzle.modulate.a = 0.3
		can_fire_burst = true 
# Inside _handle_attack_state in Sentinel.gd
	else:
		# FIRING PHASE
		var jitter = randf_range(0.95, 1.05)
		laser_line.width = 10.0 * jitter
		laser_line.modulate.a = 1.0
		muzzle.scale = Vector2(1.25, 1.25) * jitter
		muzzle.modulate.a = 1.0
		if can_fire_burst:
			ray.force_raycast_update() # Ensure it's fresh
			
			if ray.is_colliding():
				var target = ray.get_collider()
				print("SENTINEL HIT: ", target.name) # DEBUG: See what it hit!
				
				if target.is_in_group("Player"):
					# Search for stats on the player
					var p_stats = target.get_node_or_null("Stats")
					if p_stats:
						p_stats.take_damage(stats_comp.attack, stats_comp.element_type)
					else:
						# Fallback if find_child/get_node failed
						StatsComponent.take_damage(stats_comp.attack, stats_comp.element_type)
				
			can_fire_burst = false
		# Reset shot after 0.3 seconds of firing
		if charge_timer > CHARGE_TIME_LIMIT + 0.3:
			charge_timer = 0.0

func _handle_passive_state():
	sprite.play("Passive")
	laser_line.visible = false
	muzzle.visible = false
	charge_timer = 0.0
	can_fire_burst = true

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = null

func take_damage(amount, element):
	if stats_comp:
		stats_comp.take_damage(amount, element)

func die():
	queue_free()
