extends CharacterBody2D

# --- ІДЕНТИФІКАЦІЯ ---
@export var monster_id: String = "e0001" 
@export var loot_bag_scene: PackedScene


# --- КОМПОНЕНТИ ---
@onready var stats = $StatsComponent
@onready var health = $HealthComponent
@onready var name_label = $NameLabel
@onready var hp_bar = $HealthBar 
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D 

# --- ЗМІННІ ПОВЕДІНКИ (Тепер вони заповнюються з БАЗИ, а не з Інспектора) ---
var detection_radius: float = 150.0
var chase_limit: float = 300.0
var wander_radius: float = 100.0
var respawn_time: float = 5.0 
var move_speed: float = 60.0
var attack_range: float = 40.0
var attack_speed: float = 1.0

# Системні змінні
var spawn_position: Vector2
var player: CharacterBody2D = null
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var mob_level: int = 1
var is_aggressive: bool = false
var xp_reward: int = 0


enum State { IDLE, WANDER, CHASE, ATTACK, RETURN }
var state: State = State.IDLE
var wander_timer: float = 0.0
var current_attack_cooldown: float = 0.0
var wander_target_x: float = 0.0
var is_dead: bool = false

func _ready():
	spawn_position = global_position
	# Знаходимо гравця через групу
	player = get_tree().get_first_node_in_group("Player")
	
	health.health_changed.connect(_on_health_updated)
	health.died.connect(_on_death)
	
	# ЗАВАНТАЖУЄМО ВСІ ДАНІ (Включаючи AI)
	_setup_monster_from_db()
	
	_pick_new_wander_target()

func _physics_process(delta):
	if is_dead: return

	if not is_on_floor():
		velocity.y += gravity * delta

	if current_attack_cooldown > 0:
		current_attack_cooldown -= delta

	# ЛОГІКА ПЕРЕВІРКИ ГРАВЦЯ
	if player and player.is_dead and (state == State.CHASE or state == State.ATTACK):
		state = State.RETURN 

	match state:
		State.IDLE:
			velocity.x = 0
			_check_aggro_logic()
			wander_timer -= delta
			if wander_timer <= 0:
				state = State.WANDER
		
		State.WANDER:
			_check_aggro_logic()
			_move_to_x(wander_target_x)
			if abs(global_position.x - wander_target_x) < 10:
				state = State.IDLE
				wander_timer = randf_range(2.0, 5.0)
				_pick_new_wander_target()
		
		State.CHASE:
			if player and not player.is_dead:
				_move_to_x(player.global_position.x)
				var dist = global_position.distance_to(player.global_position)
				if dist > chase_limit:
					state = State.RETURN
				elif dist < attack_range:
					state = State.ATTACK
			else:
				state = State.RETURN
		
		State.ATTACK:
			velocity.x = 0
			if player and not player.is_dead:
				if current_attack_cooldown <= 0:
					_perform_attack()
				if global_position.distance_to(player.global_position) > attack_range:
					state = State.CHASE
			else:
				state = State.RETURN
		
		State.RETURN:
			_move_to_x(spawn_position.x)
			if abs(global_position.x - spawn_position.x) < 10:
				state = State.IDLE
				# Скидаємо стан агресії до бази
				var info = MonsterDB.get_mob_info(monster_id)
				is_aggressive = info.get("is_aggressive", false)
	
	move_and_slide()
	_flip_sprite()

# --- БОЙОВА ЛОГІКА ---

func take_damage(data: DamageData):
	if is_dead: return
	if player and not player.is_dead:
		state = State.CHASE
	health.take_damage(data)
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(sprite): sprite.modulate = Color.WHITE

func _perform_attack():
	current_attack_cooldown = 1.0 / attack_speed 
	if player and player.has_method("take_damage") and not player.is_dead:
		# Шкода тепер береться з StatsComponent (Сила * множник)
		var dmg_amount = stats.get_stat("physical_damage")
		var dmg_data = DamageData.new(dmg_amount, self, GameEnums.DamageType.PHYSICAL)
		player.take_damage(dmg_data)

func _check_aggro_logic():
	if not player or player.is_dead: return
	
	if is_aggressive:
		var dist = global_position.distance_to(player.global_position)
		if dist < detection_radius:
			state = State.CHASE

# --- ЗАВАНТАЖЕННЯ ДАНИХ (ОНОВЛЕНО) ---

func _setup_monster_from_db():
	var info = MonsterDB.get_mob_info(monster_id)
	if info.is_empty(): return
	
	# 1. Загальна інформація
	mob_level = info.get("level", 1)
	is_aggressive = info.get("is_aggressive", false)
	xp_reward = info.get("xp_reward", 10)
	
	# 2. Характеристики (AttributeData)
	if stats:
		# Завантажуємо паспорт
		stats.base_attributes = MonsterDB.get_attributes(monster_id)
		stats._recalculate_stats() # Оновлюємо кеш
		
		# 3. Розпаковуємо AI параметри з паспорта у змінні цього скрипта
		# Це дозволяє використовувати їх у physics_process
		var attrs = stats.base_attributes
		if attrs:
			detection_radius = attrs.detection_radius
			chase_limit = attrs.chase_limit
			wander_radius = attrs.wander_radius
			respawn_time = attrs.respawn_time
			move_speed = attrs.movement_speed
			attack_range = attrs.attack_range
			attack_speed = attrs.attack_speed
	
	# 4. Здоров'я
	if health: health.initialize_health()
	
	# 5. Візуал
	var display_name = "Lv." + str(mob_level) + " " + info.get("name", "Monster")
	name_label.modulate = Color(1, 0.6, 0.6) if is_aggressive else Color(1, 1, 1)
	name_label.text = display_name

func _on_health_updated(current, max_hp):
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current
		hp_bar.show()

func _on_death():
	is_dead = true
	
	# 1. Видаємо досвід
	if player and player.has_node("ExperienceComponent"):
		player.get_node("ExperienceComponent").add_experience(xp_reward)
	
	# 2. РОЗРАХУНОК ЛУТУ
	var drops = MonsterDB.calculate_loot(monster_id)
	
	# 3. Якщо щось випало - створюємо мішок
	if drops.size() > 0 and loot_bag_scene:
		var bag = loot_bag_scene.instantiate()
		bag.global_position = global_position # Мішок падає там, де стояв моб
		bag.items_inside = drops # Кладемо предмети всередину
		
		# Додаємо мішок у світ (не в моба, бо моб зникне!)
		get_tree().current_scene.add_child(bag)
		# Або, якщо світ - це батьківський вузол:
		# get_parent().add_child(bag)
	
	# 4. Ховаємо моба і запускаємо таймер респавну
	hide()
	collision.set_deferred("disabled", true)
	name_label.hide()
	await get_tree().create_timer(respawn_time).timeout
	respawn()

func respawn():
	global_position = spawn_position
	health.heal(9999) 
	state = State.IDLE
	show()
	name_label.show()
	collision.set_deferred("disabled", false)
	is_dead = false

func _move_to_x(target_x: float):
	# Використовуємо move_speed, завантажений з бази
	var direction = sign(target_x - global_position.x)
	velocity.x = direction * move_speed

func _pick_new_wander_target():
	# Використовуємо wander_radius, завантажений з бази
	wander_target_x = spawn_position.x + randf_range(-wander_radius, wander_radius)

func _flip_sprite():
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
