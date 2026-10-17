extends CharacterBody2D

# --- СИГНАЛИ ---
signal health_changed(new_value)
signal player_died # Сигнал для GameUI, щоб показати екран смерті
signal inventory_updated # [НОВЕ] Сигнал, що рюкзак змінився (для UI)

# --- ДАНІ ---
@export var player_data: PlayerData 

# --- ІНВЕНТАР [НОВЕ] ---
# Тут ми зберігаємо підібрані предмети
var inventory: Array[ItemData] = []

# --- КОМПОНЕНТИ ---
@onready var stats = $StatsComponent
@onready var health = $HealthComponent

# --- ВУЗЛИ ГРАВЦЯ ---
@onready var visuals = $Visuals
@onready var skeleton = $Visuals/Skeleton2D 
@onready var animation_player = $AnimationPlayer

@onready var sword_area = $SwordArea
@onready var sword_collision = $SwordArea/CollisionShape2D
@onready var weapon_sprite = $SwordArea/WeaponSprite 

@onready var overhead_health_bar = $HealthBarPlayer 

# --- ФІЗИКА ---
const PLAYER_LAYER = 2
const WORLD_LAYER = 1
const ENEMY_LAYER = 3
const ANIMATION_BASE_SPEED = 200.0

var is_attacking: bool = false
var is_dead: bool = false
var spawn_point: Vector2 

func _ready():
	add_to_group("Player")
	
	if player_data:
		player_data.calculate_physics()
		if player_data.base_stats:
			stats.base_attributes = player_data.base_stats
			stats._recalculate_stats()
	else:
		push_error("УВАГА: Не призначено PlayerData!")

	health.health_changed.connect(_on_health_updated)
	health.died.connect(_on_death)
	
	spawn_point = global_position
	
	if weapon_sprite: weapon_sprite.hide()
	if sword_collision: sword_collision.disabled = true

	# Ініціалізація ХП над головою
	if overhead_health_bar and stats and health:
		overhead_health_bar.max_value = stats.get_stat("max_health")
		overhead_health_bar.value = health.current_health

# --- ФУНКЦІЯ ДОДАВАННЯ ПРЕДМЕТА [ВИПРАВЛЕНО] ---
func add_item(new_item: ItemData):
	# 1. Якщо предмет МОЖНА стакати (наприклад, шкіра)
	if new_item.is_stackable:
		# Проходимось по всьому інвентарю
		for existing_item in inventory:
			# Якщо знайшли такий самий предмет
			if existing_item.id == new_item.id:
				
				# [ВИПРАВЛЕННЯ 1] Додаємо ту кількість, яка випала з моба, а не +1
				existing_item.quantity += new_item.quantity
				
				print("ГРАВЕЦЬ: Додав у стак -> ", existing_item.name, " (+", new_item.quantity, " шт). Всього: ", existing_item.quantity)
				
				# Оновлюємо UI і виходимо
				inventory_updated.emit()
				return

	# 2. Якщо предмет не стакається АБО це перший такий предмет у рюкзаку
	# [ВИПРАВЛЕННЯ 2] Ми просто беремо new_item, бо в ньому ВЖЕ записана
	# правильна кількість (3, 5 тощо) з MonsterDB.
	# Не треба робити item_copy.quantity = 1, бо це знищувало твій дроп.
	
	inventory.append(new_item)
	
	print("ГРАВЕЦЬ: Новий слот -> ", new_item.name, " (Кількість: ", new_item.quantity, ")")
	inventory_updated.emit()

# --- ФІЗИКА І РУХ ---
func _physics_process(delta):
	if is_dead: 
		velocity.x = 0
		move_and_slide()
		return 

	if not is_on_floor():
		var current_gravity = player_data.fall_gravity if velocity.y > 0 else player_data.jump_gravity
		velocity.y += current_gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = player_data.jump_velocity

	var direction = Input.get_axis("ui_left", "ui_right")
	var target_speed = 0.0
	
	if direction:
		var rpg_speed = stats.get_stat("movement_speed")
		target_speed = direction * rpg_speed
		
		var current_scale_y = abs(visuals.scale.y)
		
		if direction > 0:
			visuals.scale.x = current_scale_y
			sword_area.scale.x = 1
			update_ik_flip(false) 
			
		elif direction < 0:
			visuals.scale.x = -current_scale_y
			sword_area.scale.x = -1
			update_ik_flip(false)
	
	var accel = player_data.acceleration if direction else player_data.friction
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	move_and_slide()
	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		perform_attack()
		
	_update_animation_state()

# --- ФУНКЦІЯ IK ---
func update_ik_flip(should_flip: bool):
	if not skeleton: return
	var stack = skeleton.get_modification_stack()
	if not stack: return
	for i in range(stack.get_modification_count()):
		var mod = stack.get_modification(i)
		if mod is SkeletonModification2DTwoBoneIK:
			mod.flip_bend_direction = should_flip

# --- АНІМАЦІЯ ---
func _update_animation_state():
	if is_attacking: return 
	
	if is_on_floor():
		if abs(velocity.x) > 0:
			if animation_player.has_animation("run"): 
				animation_player.play("run")
				var speed_ratio = abs(velocity.x) / ANIMATION_BASE_SPEED
				animation_player.speed_scale = speed_ratio
		else:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")
				animation_player.speed_scale = 1.0

# --- БІЙ І ЗДОРОВ'Я ---
func take_damage(data: DamageData):
	if is_dead: return 
	health.take_damage(data)
	if is_inside_tree():
		visuals.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(visuals): visuals.modulate = Color.WHITE

func _on_death():
	if is_dead: return
	is_dead = true
	print("Козак пав...")
	
	collision_layer = 0 
	collision_mask = 0  
	visuals.modulate.a = 0.5 
	player_died.emit()

func respawn():
	is_dead = false
	collision_layer = 0
	set_collision_layer_value(PLAYER_LAYER, true)
	set_collision_mask_value(WORLD_LAYER, true)
	set_collision_mask_value(ENEMY_LAYER, false) 
	
	visuals.modulate.a = 1.0
	global_position = spawn_point
	velocity = Vector2.ZERO
	health.heal(9999) 
	health_changed.emit(health.current_health)

func _on_health_updated(current, max_hp):
	if overhead_health_bar:
		overhead_health_bar.value = current
	health_changed.emit(current)

func perform_attack():
	if is_dead: return
	is_attacking = true
	if weapon_sprite: weapon_sprite.show()
	
	if animation_player.has_animation("attack"):
		animation_player.play("attack")

	sword_collision.disabled = false
	await get_tree().create_timer(0.1).timeout
	
	var damage_amount = stats.get_stat("physical_damage")
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage") and body != self:
			var data = DamageData.new(damage_amount, self, GameEnums.DamageType.PHYSICAL)
			body.take_damage(data)
	
	sword_collision.disabled = true
	if weapon_sprite: weapon_sprite.hide()
	await get_tree().create_timer(0.3).timeout
	is_attacking = false
