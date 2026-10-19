extends CharacterBody2D
class_name Enemy

# --- ІДЕНТИФІКАЦІЯ ---
## Строковий ID моба з MonsterDB
@export var monster_id: String = "enm_0001" 
@export var loot_bag_scene: PackedScene

# --- СТАНИ ШТУЧНОГО ІНТЕЛЕКТУ ---
enum State { IDLE, WANDER, CHASE, ATTACK, RETURN }
var current_state: State = State.IDLE

# --- КОМПОНЕНТИ (Вузли) ---
@onready var stats: StatsComponent = $StatsComponent as StatsComponent
@onready var health: HealthComponent = $HealthComponent as HealthComponent
@onready var name_label: Label = $NameLabel as Label
@onready var hp_bar: Range = $HealthBar as Range 
@onready var sprite: Sprite2D = $Sprite2D as Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D as CollisionShape2D 

# --- ЗМІННІ ПОВЕДІНКИ (Заповнюються з MonsterDB) ---
var detection_radius: float = 150.0
var chase_limit: float = 300.0
var wander_radius: float = 100.0
var respawn_time: float = 5.0 
var move_speed: float = 60.0
var attack_range: float = 40.0
var attack_speed: float = 1.0

# --- СИСТЕМНІ ЗМІННІ ---
var spawn_position: Vector2 = Vector2.ZERO
var player: CharacterBody2D = null
var gravity: float = 980.0

var mob_level: int = 1
var is_aggressive: bool = false
var xp_reward: int = 0

var wander_timer: float = 0.0
var current_attack_cooldown: float = 0.0
var wander_target_x: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	add_to_group("Enemy")
	spawn_position = global_position
	gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	
	var player_node: Node = get_tree().get_first_node_in_group("Player")
	if player_node is CharacterBody2D:
		player = player_node as CharacterBody2D
	
	if health != null:
		health.health_changed.connect(_on_health_updated)
		health.died.connect(_on_death)
	
	_setup_monster_from_db()
	_pick_new_wander_target()

func _physics_process(delta: float) -> void:
	if is_dead: 
		return

	# [ВИПРАВЛЕННЯ] Якщо гравця не було знайдено на старті, постійно перевіряємо його наявність
	if player == null:
		var p_node: Node = get_tree().get_first_node_in_group("Player")
		if p_node is CharacterBody2D:
			player = p_node as CharacterBody2D

	if not is_on_floor():
		velocity.y += gravity * delta

	if current_attack_cooldown > 0.0:
		current_attack_cooldown -= delta

	if player != null and player.has_method("is_dead") and player.get("is_dead") == true:
		if current_state == State.CHASE or current_state == State.ATTACK:
			current_state = State.RETURN 

	match current_state:
		State.IDLE:
			velocity.x = 0.0
			_check_aggro_logic()
			wander_timer -= delta
			if wander_timer <= 0.0:
				current_state = State.WANDER
		
		State.WANDER:
			_check_aggro_logic()
			_move_to_x(wander_target_x)
			if absf(global_position.x - wander_target_x) < 10.0:
				current_state = State.IDLE
				wander_timer = randf_range(2.0, 5.0)
				_pick_new_wander_target()
		
		State.CHASE:
			if player != null and (not player.has_method("is_dead") or not player.get("is_dead")):
				_move_to_x(player.global_position.x)
				var dist: float = global_position.distance_to(player.global_position)
				if dist > chase_limit:
					current_state = State.RETURN
				elif dist < attack_range:
					current_state = State.ATTACK
			else:
				current_state = State.RETURN
		
		State.ATTACK:
			velocity.x = 0.0
			if player != null and (not player.has_method("is_dead") or not player.get("is_dead")):
				if current_attack_cooldown <= 0.0:
					_perform_attack()
				if global_position.distance_to(player.global_position) > attack_range:
					current_state = State.CHASE
			else:
				current_state = State.RETURN
		
		State.RETURN:
			_move_to_x(spawn_position.x)
			if absf(global_position.x - spawn_position.x) < 10.0:
				current_state = State.IDLE
				var info: Dictionary = MonsterDB.get_mob_info(monster_id)
				is_aggressive = bool(info.get("is_aggressive", false))
	
	move_and_slide()
	_flip_sprite()

# --- БОЙОВА ЛОГІКА ---
func take_damage(data: DamageData) -> void:
	if is_dead: 
		return
	if player != null and (not player.has_method("is_dead") or not player.get("is_dead")):
		current_state = State.CHASE
		
	if health != null:
		health.take_damage(data)
		
	if sprite != null and is_instance_valid(sprite):
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite): 
			sprite.modulate = Color.WHITE

func _perform_attack() -> void:
	current_attack_cooldown = 1.0 / maxf(0.1, attack_speed) 
	if player != null and player.has_method("take_damage") and (not player.has_method("is_dead") or not player.get("is_dead")):
		var dmg_amount: float = stats.get_stat("physical_damage") if stats != null else 5.0
		var dmg_data: DamageData = DamageData.new(dmg_amount, self, GameEnums.DamageType.PHYSICAL)
		player.call("take_damage", dmg_data)

func _check_aggro_logic() -> void:
	if player == null or (player.has_method("is_dead") and player.get("is_dead")): 
		return
	
	if is_aggressive:
		var dist: float = global_position.distance_to(player.global_position)
		if dist < detection_radius:
			current_state = State.CHASE

# --- ЗАВАНТАЖЕННЯ ДАНИХ ---
func _setup_monster_from_db() -> void:
	var info: Dictionary = MonsterDB.get_mob_info(monster_id)
	if info.is_empty(): 
		return
	
	mob_level = int(info.get("level", 1))
	is_aggressive = bool(info.get("is_aggressive", false))
	xp_reward = int(info.get("xp_reward", 10))
	
	if stats != null:
		stats.base_attributes = MonsterDB.get_attributes(monster_id)
		stats._recalculate_stats()
		
		var attrs: AttributeData = stats.base_attributes
		if attrs != null:
			detection_radius = attrs.detection_radius
			chase_limit = attrs.chase_limit
			wander_radius = attrs.wander_radius
			respawn_time = attrs.respawn_time
			move_speed = attrs.movement_speed
			attack_range = attrs.attack_range
			attack_speed = attrs.attack_speed
	
	if health != null: 
		health.initialize_health()
	
	if name_label != null:
		var display_name: String = "Lv." + str(mob_level) + " " + str(info.get("name", "Monster"))
		name_label.modulate = Color(1.0, 0.6, 0.6) if is_aggressive else Color(1.0, 1.0, 1.0)
		name_label.text = display_name

func _on_health_updated(current: float, max_hp: float) -> void:
	if hp_bar != null:
		hp_bar.max_value = max_hp
		hp_bar.value = current
		hp_bar.show()

func _on_death() -> void:
	is_dead = true
	
	if player != null and player.has_node("ExperienceComponent"):
		var xp_comp: Node = player.get_node("ExperienceComponent")
		if xp_comp.has_method("add_experience"):
			xp_comp.call("add_experience", xp_reward)
	
	var drops: Array[ItemData] = MonsterDB.calculate_loot(monster_id)
	
	if drops.size() > 0 and loot_bag_scene != null:
		var bag_instance: Node = loot_bag_scene.instantiate()
		if bag_instance is Area2D:
			var bag: Area2D = bag_instance as Area2D
			bag.global_position = global_position 
			bag.set("items_inside", drops)
			
			var current_scene: Node = get_tree().current_scene
			if current_scene != null:
				current_scene.add_child(bag)
	
	hide()
	if collision != null:
		collision.set_deferred("disabled", true)
	if name_label != null:
		name_label.hide()
		
	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _respawn() -> void:
	global_position = spawn_position
	if health != null:
		health.heal(99999.0) 
	current_state = State.IDLE
	show()
	if name_label != null:
		name_label.show()
	if collision != null:
		collision.set_deferred("disabled", false)
	is_dead = false

func _move_to_x(target_x: float) -> void:
	var direction: float = signf(target_x - global_position.x)
	velocity.x = direction * move_speed

func _pick_new_wander_target() -> void:
	wander_target_x = spawn_position.x + randf_range(-wander_radius, wander_radius)

func _flip_sprite() -> void:
	if sprite != null and velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0
