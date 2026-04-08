extends CharacterBody2D

# --- CONSTANTS ---
const MIN_JUMP = -350.0   
const MAX_JUMP = -750.0   
const MIN_CHARGE = 0.35   
const MAX_CHARGE = 1.5    
const STAMINA_DRAIN = 20.0 
const WALL_SLIDE_SPEED = 75.0 

# --- STATE VARIABLES ---
var charge_time = 0.0
var is_charging = false
var is_super_jumping = false 
var is_sprinting = false 
var can_double_jump = false
var is_wall_sliding = false
var is_leveling = false
var time_since_peak = 0.0

# --- COMBAT VARIABLES ---
var is_firing = false           
var was_laser_active = false    
var laser_charge_time = 0.0     
var laser_damage_tick = 0.75    

# --- NODES ---
@onready var animated_sprite: AnimatedSprite2D = $"0"
@onready var stats = StatsComponent
@export var projectile = preload("res://Scenes/Player Projectile.tscn")
@onready var can_interact: Node2D = null

# --- LASER NODES (CHECK THESE NAMES IN YOUR SCENE TREE!) ---
@onready var laser_muzzle = get_node_or_null("Muzzle") 
@onready var laser_beam = get_node_or_null("Muzzle/Beam")
@onready var laser_ray = get_node_or_null("Muzzle/LaserRay") # Try capital L

func _ready() -> void:
	animated_sprite.visible = true
	# Debug check at start
	if laser_ray == null:
		print("!!! ERROR: laserRay node not found. Check your Scene Tree names!")

func _physics_process(delta: float) -> void:
	# --- 1. SETUP & INPUT ---
	var direction := Input.get_axis("ui_left", "ui_right")
	var sprint_pressed := Input.is_action_pressed("Sprint")
	var jump_just_pressed := Input.is_action_just_pressed("ui_accept")
	var jump_just_released := Input.is_action_just_released("ui_accept")
	
	_handle_sprite_switching()

	# --- 2. GRAVITY & WALL LOGIC ---
	if not is_on_floor():
		var wall_dir = get_wall_normal().x
		if is_on_wall() and velocity.y > 0:
			is_wall_sliding = true
			velocity.y = min(velocity.y + get_gravity().y * delta, WALL_SLIDE_SPEED)
			
			if sprint_pressed:
				velocity.y = MIN_JUMP * stats.move_speed_mult
				velocity.x = 0
			elif jump_just_pressed:
				velocity.y = MIN_JUMP
				velocity.x = wall_dir * stats.move_speed
		else:
			is_wall_sliding = false
			velocity.y += get_gravity().y * delta
			
		if is_super_jumping and velocity.y > 0: 
			time_since_peak += delta
		else:
			time_since_peak = 0.0
	else:
		is_super_jumping = false 
		is_wall_sliding = false
		can_double_jump = true 
		time_since_peak = 0.0

	# --- 3. COMBAT (Laser vs. Projectile) ---
	if Input.is_action_pressed("Fire"):
		laser_charge_time += delta
		if laser_charge_time >= 1.2:
			_run_laser_logic(delta)
			was_laser_active = true
	else:
		_stop_laser()

	if Input.is_action_just_released("Fire"):
		if laser_charge_time < 1.2 and not was_laser_active:
			if stats.current_mana >= 20:
				fire_projectile()
				stats.current_mana -= 20
				stats.stats_changed.emit()
		
		was_laser_active = false
		laser_charge_time = 0.0
		if laser_muzzle: laser_muzzle.visible = false

	# --- 4. SPRINTING ---
	var current_speed = stats.move_speed
	is_sprinting = false
	if is_on_floor() and direction != 0 and sprint_pressed and not is_charging:
		if stats.current_stamina > 10.0:
			is_sprinting = true
			current_speed = stats.move_speed * 1.9
			stats.current_stamina -= STAMINA_DRAIN * delta
			stats.stats_changed.emit()

	# --- 5. JUMP CHARGING ---
	if is_on_floor() and Input.is_action_pressed("ui_accept"):
		charge_time += delta
		if charge_time >= MIN_CHARGE:
			is_charging = true
			animated_sprite.speed_scale = 1.0 + (charge_time * 2.0)
	
	if jump_just_released:
		if is_on_floor():
			_handle_floor_jump()
		elif can_double_jump and not is_wall_sliding:
			_handle_double_jump()
		charge_time = 0.0
		is_charging = false
		animated_sprite.speed_scale = 1.0

	# --- 6. MOVEMENT ---
	if is_charging:
		velocity.x = move_toward(velocity.x, 0, stats.move_speed)
	else:
		if is_on_floor():
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(velocity.x, direction * current_speed, 15.0)
	
	# --- 7. INTERACTION LOGIC ---
	if Input.is_action_just_pressed("Interact"):
		# Safety Gate: Only run if can_interact is NOT null
		if can_interact != null:
			print("Interacting with: ", can_interact.name)
			if can_interact.has_method("Interact"):
				can_interact.Interact()
			elif can_interact.find_parent("Shrine").has_method("Interact"):
				can_interact.find_parent("Shrine").Interact()
		else:
			# This prints to console instead of crashing the game
			print("Debug: Nothing in range to interact with.")
		
	_update_animations(direction)
	move_and_slide()

# --- COMBAT FUNCTIONS ---

func _run_laser_logic(delta: float) -> void:
	# SAFETY: If the nodes are missing, don't run the logic
	if laser_ray == null or laser_beam == null: return
	
	laser_damage_tick += delta
	
	if not is_firing and stats.current_mana < 20:
		laser_muzzle.visible = false
		return
		
	if stats.current_mana <= 0:
		_stop_laser()
		return

	is_firing = true
	stats.current_mana -= 30 * delta
	stats.stats_changed.emit()
	laser_muzzle.visible = true
	
	var dir = -1.0 if animated_sprite.flip_h else 1.0
	laser_muzzle.scale.x = abs(laser_muzzle.scale.x) * dir
	laser_muzzle.position.x = abs(laser_muzzle.position.x) * dir
	
	var color = get_element_color(stats.element_type)
	laser_muzzle.modulate = color
	laser_beam.modulate = color
	
	# PIERCING DAMAGE
	if laser_damage_tick >= 0.75:
		var space_state = get_world_2d().direct_space_state
		var laser_start = laser_muzzle.global_position
		var laser_end = laser_start + Vector2(1000 * dir, 0) 
		
		var params = PhysicsRayQueryParameters2D.create(laser_start, laser_end)
		params.collision_mask = 8 # Layer 4 (Enemies)
		params.collide_with_areas = true
		
		var hit_list = [] 
		for i in 10:
			params.exclude = hit_list 
			var result = space_state.intersect_ray(params)
			if result:
				var target = result.collider
				if target.is_in_group("Enemy") and target.find_child("EnemyStatsCOmponent"):
					target.find_child("EnemyStatsCOmponent").take_damage(round(stats.base_attack * 3.5), stats.element_type)
				hit_list.append(target.get_rid()) 
			else:
				break 
		laser_damage_tick = 0.0 

	# VISUAL BEAM
	laser_ray.force_raycast_update()
	if laser_ray.is_colliding():
		var cast_point = laser_ray.get_collision_point()
		laser_beam.points[1] = laser_beam.to_local(cast_point)
	else:
		laser_beam.points[1] = Vector2(1000, 0)

func _stop_laser():
	is_firing = false
	if laser_muzzle: laser_muzzle.visible = false

func fire_projectile():
	var proj = projectile.instantiate()
	
	# 1. Set the element first (The setter handles the visual)
	if "element_type" in proj:
		proj.element_type = stats.element_type
	
	# 2. Add to tree so it exists in the world
	get_tree().current_scene.add_child(proj)
	
	# 3. Determine direction and rotation
	var is_aiming_up = Input.is_action_pressed("ui_up")
	var dir_x: float = -1.0 if animated_sprite.flip_h else 1.0
	
	if is_aiming_up:
		proj.direction = Vector2(0, -1)
		proj.rotation_degrees = -90 
	else:
		# Set the whole vector at once to be safe
		proj.direction = Vector2(dir_x, 0)
		proj.rotation_degrees = 0
	
	# 4. NOW set the position (Now that direction is defined)
	# Using dir_x * 10 to offset it from the player's center
	proj.global_position = global_position + Vector2(dir_x * 10, -5 if is_aiming_up else 0)
	
	# 5. Set scale
	proj.scale = Vector2(0.3 * dir_x, 0.3)
# --- SYSTEM FUNCTIONS ---

func _handle_sprite_switching():
	var target_name = str(StatsComponent.element_type)
	if animated_sprite.name != target_name:
		var new_sprite = find_child(target_name, false, false)
		if new_sprite and new_sprite is AnimatedSprite2D:
			animated_sprite.visible = false
			animated_sprite = new_sprite
			animated_sprite.visible = true

func _handle_floor_jump():
	if is_charging:
		var jump_pwr = remap(clamp(charge_time, 0, MAX_CHARGE), 0, MAX_CHARGE, MIN_JUMP - 100, MAX_JUMP)
		velocity.y = jump_pwr
		is_super_jumping = true
		stats.current_stamina = max(stats.current_stamina - 35, 0)
		stats.stats_changed.emit()
	else:
		velocity.y = MIN_JUMP
		is_super_jumping = false 
		if is_sprinting:
			velocity.x *= 1.5 

func _handle_wall_jump():
	var wall_normal = get_wall_normal()
	velocity.x = wall_normal.x * stats.move_speed * 1.5
	velocity.y = MIN_JUMP
	is_wall_sliding = false
	can_double_jump = true 
	is_super_jumping = false

func _handle_double_jump():
	velocity.y = MIN_JUMP
	can_double_jump = false
	is_super_jumping = true

func _update_animations(direction):
	if is_leveling:
		if animated_sprite.animation != "LevelUp":
			animated_sprite.play("LevelUp")
			if not animated_sprite.animation_finished.is_connected(_on_levelup_finished):
				animated_sprite.animation_finished.connect(_on_levelup_finished, CONNECT_ONE_SHOT)
		return

	var is_aiming_up = Input.is_action_pressed("ui_up")
	if not is_wall_sliding and direction != 0:
		animated_sprite.flip_h = (direction < 0)

	if is_wall_sliding:
		animated_sprite.flip_h = (get_wall_normal().x < 0)
		if Input.is_action_pressed("ui_accept"):
			animated_sprite.pause()
		else:
			animated_sprite.play("Wall")
	elif is_charging:
		animated_sprite.play("Charge")
	elif is_on_floor():
		if is_aiming_up:
			animated_sprite.play("Walk-UP" if direction != 0 else "Idle-UP")
		elif is_sprinting:
			animated_sprite.play("Sprint")
		elif direction != 0:
			animated_sprite.play("Walk")
		else:
			animated_sprite.play("Idle")
	else:
		if is_super_jumping:
			if velocity.y <= 0 or time_since_peak < 0.15:
				animated_sprite.play("Air")
			else:
				animated_sprite.play("Fall")
		elif velocity.y > 400:
			animated_sprite.play("Fall")
		else:
			animated_sprite.play("Idle-UP" if is_aiming_up else "Idle")

func _on_levelup_finished():
	is_leveling = false

func play_damaged_effect():
	velocity.y = -250 
	var tween = create_tween()
	for i in 4:
		tween.tween_property(animated_sprite, "modulate", Color(1, 0, 0, 0.5), 0.1)
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.1)

func _on_damage_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		var enemy_stats = body.find_child("EnemyStatsComponent")
		if enemy_stats:
			stats.take_damage(enemy_stats.attack, enemy_stats.element_type)
	else:
		stats.take_damage(20.0, Elements.Type.NHLM)
	stats.stats_changed.emit()

func _on_interaction_area_area_exited(area: Area2D) -> void:
	if can_interact == area or (can_interact and can_interact == area.get_parent()):
		print("Leaving interaction range of: ", area.name)
		can_interact = null

func get_element_color(type: int) -> Color:
	match type:
		3: return Color.ORANGE        # Pyro
		0: return Color.CYAN          # Cryo
		2: return Color.SKY_BLUE      # Hydro
		5: return Color.AQUA          # Anemo
		4: return Color.SADDLE_BROWN  # Geo
		1: return Color.LIME_GREEN    # Dendro
		6: return Color.PURPLE        # Electro
		7: return Color(0.2, 0, 0.35)  # N/hlm
		_: return Color.WHITE

func _on_interaction_area_area_entered(area: Area2D) -> void:
	# SUPER DEBUG: This will print the name of EVERYTHING the interaction area touches
	print("Tun touched something: ", area.name, " | Groups: ", area.get_groups())
	
	# 1. Check if the Area itself is the 'Interactable'
	if area.is_in_group("Interactable"):
		can_interact = area
		print("SUCCESS: Found Interactable Area: ", area.name)
	
	# 2. Or check if its Parent (The Shrine) is the 'Interactable'
	elif area.get_parent().is_in_group("Interactable"):
		can_interact = area.get_parent()
		print("SUCCESS: Found Interactable Parent: ", can_interact.name)
