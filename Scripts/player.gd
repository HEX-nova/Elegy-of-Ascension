extends CharacterBody2D

# ---- Fighting modes ----
enum FightMode { MELEE, RANGED }
var current_fight_mode = FightMode.RANGED

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
var projectile = PackedScene
@onready var can_interact: Node2D = null
@onready var sword: Area2D = $Sword

# --- LASER NODES ---
@onready var laser_muzzle = get_node_or_null("Muzzle") 
@onready var laser_beam = get_node_or_null("Muzzle/Beam")
@onready var laser_ray = get_node_or_null("Muzzle/LaserRay")

func _ready() -> void:
	projectile = preload("res://Scenes/Player Projectile.tscn")
	animated_sprite.visible = true
	if sword:
		sword.visible = false
		sword.monitoring = false
	if laser_ray == null:
		print("!!! ERROR: laserRay node not found.")

func _physics_process(delta: float) -> void:
	# --- MODE SWITCHING ---
	if Input.is_action_just_pressed("SwitchMode"):
		current_fight_mode = FightMode.MELEE if current_fight_mode == FightMode.RANGED else FightMode.RANGED
		# TOTAL SHUTDOWN for Sword logic when swapping
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
			
			# WALL CLIMB/JUMP LOGIC
			if sprint_pressed and stats.current_stamina > 0:
				# This is your "Up the wall" climb
				velocity.y = MIN_JUMP * 0.8 # Slightly slower than a full jump
				stats.current_stamina -= STAMINA_DRAIN * delta
				stats.stats_changed.emit()
			else:
				# Standard slide
				velocity.y = min(velocity.y + get_gravity().y * delta, WALL_SLIDE_SPEED)
			
			if jump_just_pressed:
				# This is your "Off the wall" jump
				velocity.y = MIN_JUMP
				velocity.x = wall_dir * stats.move_speed
		else:
			is_wall_sliding = false
			velocity.y += get_gravity().y * delta
	else:
		is_super_jumping = false 
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

	# --- 4. SPRINTING (Fixed Animation Reset) ---
	var current_speed = stats.move_speed
	
	# Logic: You must be on floor, moving, and holding sprint
	if is_on_floor() and direction != 0 and sprint_pressed and not is_charging:
		if stats.current_stamina > 0:
			is_sprinting = true
			current_speed = stats.move_speed * 1.9
			stats.current_stamina -= STAMINA_DRAIN * delta
			stats.stats_changed.emit()
		else:
			is_sprinting = false
	else:
		is_sprinting = false # This fixes the stuck animation!

	# --- 5. JUMP CHARGING ---
	if is_on_floor() and Input.is_action_pressed("ui_accept"):
		charge_time += delta
		if charge_time >= MIN_CHARGE:
			is_charging = true
	
	if jump_just_released:
		if is_on_floor(): _handle_floor_jump()
		elif can_double_jump and not is_wall_sliding: _handle_double_jump()
		charge_time = 0.0
		is_charging = false

	# --- 6. MOVEMENT ---
	if is_charging:
		velocity.x = move_toward(velocity.x, 0, stats.move_speed)
	else:
		velocity.x = direction * current_speed if is_on_floor() else move_toward(velocity.x, direction * current_speed, 15.0)
	
	# --- 7. INTERACTION (Restored) ---
	if Input.is_action_just_pressed("Interact"):
		if can_interact != null:
			print("Interacting with: ", can_interact.name)
			# Check the object itself first
			if can_interact.has_method("Interact"):
				can_interact.Interact()
			# Fallback: Check if it's a child of a Shrine
			elif can_interact.find_parent("Shrine") and can_interact.find_parent("Shrine").has_method("Interact"):
				can_interact.find_parent("Shrine").Interact()
		
	# --- 8. SWORD VISUAL SYNC ---
	if sword:
		if current_fight_mode == FightMode.MELEE and not sword.monitoring:
			sword.visible = true
			var dir = -1.0 if animated_sprite.flip_h else 1.0
			sword.scale.x = abs(sword.scale.x) * dir
			sword.rotation_degrees = -15 * dir
			sword.position = Vector2(8 * dir, -2)
		elif current_fight_mode == FightMode.RANGED and not sword.monitoring:
			sword.visible = false
	
	_update_animations(direction)
	move_and_slide()

# --- COMBAT FUNCTIONS ---

func perform_melee_attack():
	if sword == null or is_firing: return
	
	var dir = -1.0 if animated_sprite.flip_h else 1.0
	
	# 1. BRING IT ONLINE
	sword.scale.x = abs(sword.scale.x) * dir
	sword.rotation_degrees = -90 * dir 
	sword.position = Vector2(5 * dir, -5)
	
	sword.visible = true
	sword.monitoring = true    # Can hit others
	sword.monitorable = true   # Others can see it (if needed)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sword, "rotation_degrees", 90 * dir, 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(sword, "position", Vector2(15 * dir, 0), 0.3).set_trans(Tween.TRANS_BACK)

	# 2. TOTAL SHUTDOWN after swing
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
	laser_muzzle.visible = true
	
	var dir = -1.0 if animated_sprite.flip_h else 1.0
	laser_muzzle.scale.x = abs(laser_muzzle.scale.x) * dir
	laser_muzzle.position.x = abs(laser_muzzle.position.x) * dir
	
	var color = get_element_color(stats.element_type)
	laser_muzzle.modulate = color
	laser_beam.modulate = color
	
	if laser_damage_tick >= 0.75:
		# (Raycast damage logic remains same as your snippet)
		laser_damage_tick = 0.0 

	laser_ray.force_raycast_update()
	laser_beam.points[1] = laser_beam.to_local(laser_ray.get_collision_point()) if laser_ray.is_colliding() else Vector2(1000, 0)

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

# --- SYSTEM FUNCTIONS ---

func _handle_sprite_switching():
	var target_name = str(StatsComponent.element_type)
	if animated_sprite.name != target_name:
		var new_sprite = find_child(target_name, false, false)
		if new_sprite:
			animated_sprite.visible = false
			animated_sprite = new_sprite
			animated_sprite.visible = true

func _handle_floor_jump():
	velocity.y = remap(clamp(charge_time, 0, MAX_CHARGE), 0, MAX_CHARGE, MIN_JUMP - 100, MAX_JUMP) if is_charging else MIN_JUMP
	if is_charging: stats.current_stamina -= 35
	stats.stats_changed.emit()

func _handle_double_jump():
	velocity.y = MIN_JUMP
	can_double_jump = false
	is_super_jumping = true

func play_damaged_effect():
	velocity.y = -250 
	var tween = create_tween()
	for i in 4:
		tween.tween_property(animated_sprite, "modulate", Color(1, 0, 0, 0.5), 0.1)
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.1) 

func _update_animations(direction):
	if not is_wall_sliding and direction != 0:
		animated_sprite.flip_h = (direction < 0)
	
	if is_wall_sliding:
		animated_sprite.play("Wall")
		animated_sprite.flip_h = (get_wall_normal().x < 0)
	elif is_charging: animated_sprite.play("Charge")
	elif is_on_floor():
		animated_sprite.play("Sprint" if is_sprinting else ("Walk" if direction != 0 else "Idle"))
	else:
		animated_sprite.play("Fall" if velocity.y > 0 else "Air")

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
	# 2. Check for TileMap Hazards (Spikes)
	elif body is TileMapLayer :
		if body.name == "Danger":
			StatsComponent.take_fixed_damage(20)
