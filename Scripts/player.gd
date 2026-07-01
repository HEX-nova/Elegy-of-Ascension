extends CharacterBody2D

# ---- Fighting modes ----
enum FightMode { MELEE, RANGED }
var current_fight_mode = FightMode.RANGED

# --- CONSTANTS ---
const MIN_JUMP = -450.0   
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
var time_since_peak = 0.0
var is_leveling = false:
	set(value):
		is_leveling = value
		if is_leveling == true:
			velocity = Vector2.ZERO
			_start_levelup_safety_timer()

# --- COMBAT VARIABLES ---
var is_firing = false           
var was_laser_active = false    
var laser_charge_time = 0.0     
var laser_damage_tick = 0.75    

# --- NODES ---
@onready var animated_sprite: AnimatedSprite2D = $"0"
@onready var stats = StatsComponent
var projectile = PackedScene
@onready var can_interact: Node2D = null
@onready var sword: Area2D = $Weapon

# --- LASER NODES ---
@onready var laser_muzzle = get_node_or_null("Muzzle") 
@onready var laser_beam = get_node_or_null("Muzzle/Beam")
@onready var laser_ray = get_node_or_null("Muzzle/LaserRay")

func _ready() -> void:
	projectile = preload("res://Scenes/Player Projectile.tscn")
	animated_sprite.visible = true
	
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
		
	if sword:
		sword.visible = false
		sword.monitoring = false
	if laser_ray == null:
		print("!!! ERROR: laserRay node not found.")

func _physics_process(delta: float) -> void:
	if is_leveling:
		velocity = Vector2.ZERO
		_update_animations(0, 0)
		move_and_slide()
		return

	# --- Stamina handling ---
	if not is_charging and not is_sprinting:
		StatsComponent.current_stamina = move_toward(StatsComponent.current_stamina, StatsComponent.max_stamina, Elements.get_stat(10, StatsComponent.element_type) * 5 * delta)
	
	# --- MODE SWITCHING ---
	if Input.is_action_just_pressed("SwitchMode"):
		current_fight_mode = FightMode.MELEE if current_fight_mode == FightMode.RANGED else FightMode.RANGED
		if sword:
			sword.visible = false
			sword.monitoring = false
			sword.monitorable = false
		is_sprinting = false
		is_charging = false
		_stop_laser()
		animated_sprite.speed_scale = 1.0

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
			if sprint_pressed and stats.current_stamina > 0:
				velocity.y = MIN_JUMP / stats.weight
				stats.current_stamina -= STAMINA_DRAIN * delta
				stats.stats_changed.emit()
			else:
				velocity.y = min(velocity.y + get_gravity().y * delta, WALL_SLIDE_SPEED) / stats.weight
			if jump_just_pressed:
				velocity.y = MIN_JUMP / stats.weight
				velocity.x = wall_dir * stats.move_speed
		else:
			is_wall_sliding = false
			velocity.y += get_gravity().y * delta
	else:
		is_wall_sliding = false
		can_double_jump = true 

	# --- 3. COMBAT (Mode Dependent) ---
	if current_fight_mode == FightMode.RANGED:
		if Input.is_action_pressed("Fire"):
			laser_charge_time += delta
			if laser_charge_time >= 1.2:
				_run_laser_logic(delta)
				was_laser_active = true
		else:
			_stop_laser()

		if Input.is_action_just_released("Fire"):
			if laser_charge_time < 1.2 and not was_laser_active:
				if stats.current_atheer >= 20:
					fire_projectile()
					stats.current_atheer -= 20
					stats.stats_changed.emit()
			was_laser_active = false
			laser_charge_time = 0.0
	else:
		_stop_laser()
		if Input.is_action_just_pressed("Fire"):
			perform_melee_attack()

	# --- 4. SPRINTING ---
	var current_speed = stats.move_speed
	if is_on_floor() and direction != 0 and sprint_pressed and not is_charging:
		if stats.current_stamina > 0:
			is_sprinting = true
			current_speed = stats.move_speed * 1.9
			stats.current_stamina -= STAMINA_DRAIN * delta
			stats.stats_changed.emit()
		else:
			is_sprinting = false
	else:
		is_sprinting = false

	# --- 5. JUMP CHARGING ---
	if is_on_floor() and Input.is_action_pressed("ui_accept"):
		charge_time += delta
		if charge_time >= MIN_CHARGE:
			is_charging = true
			var charge_ratio = clamp((charge_time - MIN_CHARGE) / (MAX_CHARGE - MIN_CHARGE), 0.0, 1.0)
			animated_sprite.speed_scale = remap(charge_ratio, 0.0, 1.0, 1.0, 3.0)
			
	if jump_just_released:
		animated_sprite.speed_scale = 1.0
		if is_on_floor(): 
			_handle_floor_jump()
		elif can_double_jump and not is_wall_sliding: 
			_handle_double_jump()
		charge_time = 0.0
		is_charging = false

	# --- 6. MOVEMENT ---
	if is_charging:
		velocity.x = move_toward(velocity.x, 0, stats.move_speed)
	else:
		velocity.x = direction * current_speed if is_on_floor() else move_toward(velocity.x, direction * current_speed, 15.0)

	# --- 7. INTERACTION ---
	if Input.is_action_just_pressed("Interact") and can_interact != null:
		if can_interact.has_method("Interact"):
			can_interact.Interact()
		elif can_interact.find_parent("Shrine") and can_interact.find_parent("Shrine").has_method("Interact"):
			can_interact.find_parent("Shrine").Interact()

	# --- 8. SWORD VISUAL SYNC ---
	if sword and not sword.monitoring:
		if current_fight_mode == FightMode.MELEE:
			sword.visible = true
			var dir = -1.0 if animated_sprite.flip_h else 1.0
			sword.scale.x = abs(sword.scale.x) * dir
			sword.rotation_degrees = -15 * dir
			sword.position = Vector2(8 * dir, -2)
		else:
			sword.visible = false

	var h_dir = Input.get_axis("ui_left", "ui_right")
	var v_dir = Input.get_axis("ui_up", "ui_down")
	_update_animations(h_dir, v_dir)
	
	
	
	move_and_slide()

# --- SYSTEM JUMP OVERRIDES ---

func _handle_floor_jump():
	if is_charging:
		velocity.y = remap(clamp(charge_time, 0, MAX_CHARGE), 0, MAX_CHARGE, MIN_JUMP - 100, MAX_JUMP)
		stats.current_stamina -= 35
		is_super_jumping = true 
	else:
		velocity.y = MIN_JUMP
		is_super_jumping = false
	stats.stats_changed.emit()

func _handle_double_jump():
	velocity.y = MIN_JUMP
	can_double_jump = false
	is_super_jumping = true

func _start_levelup_safety_timer() -> void:
	var safety_timer = get_tree().create_timer(1.5)
	safety_timer.timeout.connect(func():
		if is_leveling:
			is_leveling = false
	)

func _on_animation_finished() -> void:
	if is_leveling:
		is_leveling = false

# --- COMBAT FUNCTIONS ---

func perform_melee_attack():
	if sword == null or is_firing: return
	var dir = -1.0 if animated_sprite.flip_h else 1.0
	sword.scale.x = abs(sword.scale.x) * dir
	sword.rotation_degrees = -90 * dir 
	sword.position = Vector2(5 * dir, -5)
	sword.visible = true
	sword.monitoring = true    
	sword.monitorable = true   
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sword, "rotation_degrees", 90 * dir, 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(sword, "position", Vector2(15 * dir, 0), 0.3).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_callback(func():
		sword.visible = false
		sword.monitoring = false
		sword.monitorable = false
	)

func _run_laser_logic(delta: float) -> void:
	if laser_ray == null or laser_beam == null: return
	laser_damage_tick += delta
	if stats.current_atheer <= 0:
		_stop_laser()
		return
	is_firing = true
	stats.current_atheer -= 30 * delta
	stats.stats_changed.emit()
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir == Vector2.ZERO:
		input_dir = Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT
	var laser_direction = input_dir.normalized()
	laser_muzzle.visible = true
	laser_muzzle.rotation = laser_direction.angle()
	var color = get_element_color(stats.element_type)
	laser_muzzle.modulate = color
	laser_beam.modulate = color

	if laser_damage_tick >= 0.75:
		laser_damage_tick = 0.0
		var space_state = get_world_2d().direct_space_state
		var start_pos = laser_ray.global_position
		var end_pos = start_pos + (laser_direction * 1000)
		var query_params = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
		query_params.collision_mask = laser_ray.collision_mask
		query_params.exclude = [self.get_rid()]
		var hits_count = 0
		while hits_count < 10:
			var result = space_state.intersect_ray(query_params)
			if result.is_empty(): break
			var collider = result.collider
			var stats_node = collider.get_node_or_null("EnemyStatsComponent")
			if stats_node == null:
				stats_node = collider.get_parent().get_node_or_null("EnemyStatsComponent")
			if stats_node and stats_node.has_method("take_damage"):
				stats_node.take_damage(stats.attack * 3.5, stats.element_type)
			if not collider.is_in_group("Enemy") and not stats_node: break
			query_params.from = result.position + (laser_direction * 2.0)
			hits_count += 1
	laser_beam.rotation = 0 
	laser_beam.points[1] = laser_beam.to_local(laser_ray.global_position + (laser_direction * 1000))

func _stop_laser():
	is_firing = false
	if laser_muzzle: laser_muzzle.visible = false

func fire_projectile():
	var proj = projectile.instantiate()
	if "element_type" in proj: proj.element_type = stats.element_type
	get_tree().current_scene.add_child(proj)
	var dir_x: float = -1.0 if animated_sprite.flip_h else 1.0
	proj.direction = Vector2(dir_x, 0)
	proj.global_position = global_position + Vector2(dir_x * 10, 0)
	proj.scale = Vector2(0.3 * dir_x, 0.3)

func _handle_sprite_switching():
	var target_name = str(StatsComponent.element_type)
	if stats.current_health <= 0 :
		animated_sprite.visible = false
		animated_sprite = find_child("Death")
		animated_sprite.visible = true
		animated_sprite.play(str(stats.element_type))
	elif animated_sprite.name != target_name:
		var new_sprite = find_child(target_name, false, false)
		if new_sprite:
			animated_sprite.visible = false
			animated_sprite = new_sprite
			animated_sprite.visible = true
			if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
				animated_sprite.animation_finished.connect(_on_animation_finished)

func play_damaged_effect():
	velocity.y = -350 
	var tween = create_tween()
	for i in 4:
		tween.tween_property(animated_sprite, "modulate", Color(1, 0, 0, 0.5), 0.1)
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.1) 

# --- CRITICAL FIX: REAL-TIME VELOCITY AND POSITION CALCULATOR ---

func _update_animations(direction: float, v_dir: float):
	if not is_wall_sliding and direction != 0:
		animated_sprite.flip_h = (direction < 0)
		
	var anim_suffix = "-UP" if v_dir < 0 else ""

	# 1. LevelUp Display Guard
	if is_leveling:
		if animated_sprite.sprite_frames.has_animation("LevelUp"):
			animated_sprite.play("LevelUp")
		else:
			animated_sprite.play("Idle" + anim_suffix)
		return

	# 2. Wall Slide State Animation Guard
	if is_wall_sliding:
		animated_sprite.play("Wall")
		animated_sprite.flip_h = (get_wall_normal().x < 0)
		return 

	# 3. Floor Charging Animation Guard
	if is_charging:
		animated_sprite.play("Charge")
		return

	# 4. Air States (FORCE AIR WHEN LAUNCHED)
	# Added velocity override check so micro-frames on floor don't trap the super jump!
	if not is_on_floor() or velocity.y < -10.0:
		# --- Moving Upwards (Jumping) ---
		if velocity.y < -50.0:
			if is_super_jumping:
				animated_sprite.play("Air")  # Release jump is air (long jump)
			else:
				animated_sprite.play("Idle" + anim_suffix) # Short hop stays crisp as idle
				
		# --- The Peak & Moving Downwards (Falling) ---
		else: 
			if is_super_jumping:
				if velocity.y >= -50.0 and velocity.y < 200.0:
					animated_sprite.play("Idle" + anim_suffix) # Idle exactly at the peak!
				else:
					animated_sprite.play("Fall") # Rapid super fall after peak passes
			else:
				if velocity.y > 450.0:
					animated_sprite.play("Fall")
				else:
					animated_sprite.play("Idle" + anim_suffix) # Small fall is idle

	# 5. Standard Floor States
	else:
		is_super_jumping = false
		animated_sprite.speed_scale = 1.0
		
		if direction != 0:
			var move_type = "Sprint" if is_sprinting else "Walk"
			animated_sprite.play(move_type + anim_suffix)
		else:
			animated_sprite.play("Idle" + anim_suffix)

func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("Interactable"): can_interact = area
	elif area.get_parent().is_in_group("Interactable"): can_interact = area.get_parent()

func _on_interaction_area_area_exited(area: Area2D) -> void:
	if can_interact == area or (can_interact and can_interact == area.get_parent()):
		can_interact = null

func _on_damage_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		var enemy = body.find_child("EnemyStatsComponent")
		StatsComponent.take_damage(enemy.attack, enemy.element_type)
	elif body is TileMapLayer:
		if body.name == "Danger":
			StatsComponent.take_fixed_damage(20)

func get_element_color(type: int) -> Color:
	match type:
		3: return Color.ORANGE
		0: return Color.CYAN
		2: return Color.SKY_BLUE
		5: return Color.AQUA
		4: return Color.SADDLE_BROWN
		1: return Color.LIME_GREEN
		6: return Color.PURPLE
		7: return Color(0.2, 0, 0.35)
		_: return Color.WHITE
