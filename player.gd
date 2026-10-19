extends CharacterBody2D
class_name Player

# --- СИГНАЛИ ---
signal health_changed(new_value: float)
signal player_died
signal inventory_updated
signal equipment_changed

# --- ДАНІ ---
@export var player_data: PlayerData

# --- ІНВЕНТАР ТА ЕКІПІРУВАННЯ ---
var inventory: Array[ItemData] = []
# Словник одягнених речей: { EquipmentData.EquipmentSlot: EquipmentData }
var equipped_items: Dictionary = {}

# --- КОМПОНЕНТИ ---
@onready var stats: StatsComponent = $StatsComponent as StatsComponent
@onready var health: HealthComponent = $HealthComponent as HealthComponent

# --- ВУЗЛИ ГРАВЦЯ (Збережено структуру player.tscn) ---
@onready var visuals: Node2D = $Visuals as Node2D
@onready var skeleton: Skeleton2D = $Visuals/Skeleton2D as Skeleton2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer as AnimationPlayer

@onready var sword_area: Area2D = $SwordArea as Area2D
@onready var sword_collision: CollisionShape2D = $SwordArea/CollisionShape2D as CollisionShape2D
@onready var weapon_sprite: Sprite2D = $SwordArea/WeaponSprite as Sprite2D

@onready var overhead_health_bar: Range = $HealthBarPlayer as Range

# --- КОНСТАНТИ ФІЗИКИ ---
const PLAYER_LAYER: int = 2
const WORLD_LAYER: int = 1
const ENEMY_LAYER: int = 3
const ANIMATION_BASE_SPEED: float = 200.0

var is_attacking: bool = false
var is_dead: bool = false
var spawn_point: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("Player")
	_ensure_movement_inputs()
	
	if player_data != null:
		player_data.calculate_physics()
		if player_data.base_stats != null and stats != null:
			stats.base_attributes = player_data.base_stats
			stats._recalculate_stats()
	else:
		push_error("Player: Не призначено ресурс PlayerData!")

	if health != null:
		health.health_changed.connect(_on_health_updated)
		health.died.connect(_on_death)
	
	spawn_point = global_position
	
	if weapon_sprite != null:
		weapon_sprite.hide()
	if sword_collision != null:
		sword_collision.disabled = true

	if overhead_health_bar != null and stats != null and health != null:
		overhead_health_bar.max_value = stats.get_stat("max_health")
		overhead_health_bar.value = health.current_health

## Програмна прив'язка клавіш A та D до стандартних дій руху вліво/вправо
func _ensure_movement_inputs() -> void:
	var key_a: InputEventKey = InputEventKey.new()
	key_a.physical_keycode = KEY_A
	if not InputMap.action_has_event("ui_left", key_a):
		InputMap.action_add_event("ui_left", key_a)
		
	var key_d: InputEventKey = InputEventKey.new()
	key_d.physical_keycode = KEY_D
	if not InputMap.action_has_event("ui_right", key_d):
		InputMap.action_add_event("ui_right", key_d)

## Додавання предмета в інвентар з урахуванням ліміту стаків
func add_item(new_item: ItemData) -> void:
	if new_item == null or new_item.quantity <= 0:
		return
		
	if new_item.is_stackable:
		for existing_item: ItemData in inventory:
			if existing_item.id == new_item.id:
				var max_limit: int = maxi(1, existing_item.max_stack_size)
				if existing_item.quantity < max_limit:
					var space_left: int = max_limit - existing_item.quantity
					var to_add: int = mini(space_left, new_item.quantity)
					existing_item.quantity += to_add
					new_item.quantity -= to_add
					if new_item.quantity <= 0:
						inventory_updated.emit()
						return

	var item_copy: ItemData = new_item.duplicate() as ItemData
	item_copy.quantity = maxi(1, new_item.quantity)
	inventory.append(item_copy)
	inventory_updated.emit()

## Одягання екіпірування з автоматичним нарахуванням бонусів характеристик
func equip_item(equip_data: EquipmentData) -> void:
	if equip_data == null or stats == null:
		return
		
	var slot: int = equip_data.slot_type
	if equipped_items.has(slot):
		unequip_slot(slot)
		
	equipped_items[slot] = equip_data
	var source_key: String = "equip_slot_" + str(slot)
	
	if equip_data.damage > 0.0:
		stats.add_modifier("physical_damage", source_key, equip_data.damage)
	if equip_data.defense > 0.0:
		stats.add_modifier("armor", source_key, equip_data.defense)
	if equip_data.bonus_strength != 0.0:
		stats.add_modifier("strength", source_key, equip_data.bonus_strength)
	if equip_data.bonus_dexterity != 0.0:
		stats.add_modifier("dexterity", source_key, equip_data.bonus_dexterity)
	if equip_data.bonus_intelligence != 0.0:
		stats.add_modifier("intelligence", source_key, equip_data.bonus_intelligence)
	if equip_data.bonus_constitution != 0.0:
		stats.add_modifier("constitution", source_key, equip_data.bonus_constitution)
	if equip_data.bonus_speed != 0.0:
		stats.add_modifier("movement_speed", source_key, equip_data.bonus_speed)
		
	if equip_data.equipment_texture != null and weapon_sprite != null and slot == EquipmentData.EquipmentSlot.WEAPON:
		weapon_sprite.texture = equip_data.equipment_texture
		
	equipment_changed.emit()

## Зняття предмета зі слота екіпірування
func unequip_slot(slot: int) -> void:
	if not equipped_items.has(slot) or stats == null:
		return
	var source_key: String = "equip_slot_" + str(slot)
	stats.remove_all_modifiers_from_source(source_key)
	equipped_items.erase(slot)
	equipment_changed.emit()

# --- ФІЗИКА І РУХ (Без стрибків, суворо по лінії землі) ---
func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0.0
		move_and_slide()
		return

	# Гравітація утримує персонажа на поверхні землі
	if not is_on_floor():
		var current_gravity: float = player_data.fall_gravity if player_data != null else 1200.0
		velocity.y += current_gravity * delta
	else:
		velocity.y = 0.0

	var direction: float = Input.get_axis("ui_left", "ui_right")
	var target_speed: float = 0.0
	
	if direction != 0.0:
		var rpg_speed: float = stats.get_stat("movement_speed") if stats != null else 200.0
		target_speed = direction * rpg_speed
		
		if visuals != null:
			var current_scale_y: float = absf(visuals.scale.y)
			if direction > 0.0:
				visuals.scale.x = current_scale_y
				if sword_area != null:
					sword_area.scale.x = 1.0
				update_ik_flip(false)
			elif direction < 0.0:
				visuals.scale.x = -current_scale_y
				if sword_area != null:
					sword_area.scale.x = -1.0
				update_ik_flip(false)
	
	var accel: float = 1200.0
	if player_data != null:
		accel = player_data.acceleration if direction != 0.0 else player_data.friction
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	move_and_slide()
	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		perform_attack()
		
	_update_animation_state()

## Корекція згину кісток інверсної кінематики Skeleton2D
func update_ik_flip(should_flip: bool) -> void:
	if skeleton == null:
		return
	var stack: SkeletonModificationStack2D = skeleton.get_modification_stack()
	if stack == null:
		return
	for i: int in range(stack.get_modification_count()):
		var mod: SkeletonModification2D = stack.get_modification(i)
		if mod is SkeletonModification2DTwoBoneIK:
			var ik_mod: SkeletonModification2DTwoBoneIK = mod as SkeletonModification2DTwoBoneIK
			ik_mod.flip_bend_direction = should_flip

## Керування станами анімацій скелета
func _update_animation_state() -> void:
	if is_attacking or animation_player == null:
		return
	
	if is_on_floor():
		if absf(velocity.x) > 1.0:
			if animation_player.has_animation("run"):
				animation_player.play("run")
				var speed_ratio: float = absf(velocity.x) / ANIMATION_BASE_SPEED
				animation_player.speed_scale = clampf(speed_ratio, 0.5, 3.0)
		else:
			if animation_player.has_animation("idle"):
				animation_player.play("idle")
				animation_player.speed_scale = 1.0

# --- БІЙ І ЗДОРОВ'Я ---
func take_damage(data: DamageData) -> void:
	if is_dead or health == null:
		return
	health.take_damage(data)
	if is_inside_tree() and visuals != null:
		visuals.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(visuals):
			visuals.modulate = Color.WHITE

func _on_death() -> void:
	if is_dead:
		return
	is_dead = true
	collision_layer = 0
	collision_mask = 0
	if visuals != null:
		visuals.modulate.a = 0.5
	player_died.emit()

func respawn() -> void:
	is_dead = false
	collision_layer = 0
	set_collision_layer_value(PLAYER_LAYER, true)
	set_collision_mask_value(WORLD_LAYER, true)
	set_collision_mask_value(ENEMY_LAYER, false)
	
	if visuals != null:
		visuals.modulate.a = 1.0
	global_position = spawn_point
	velocity = Vector2.ZERO
	if health != null:
		health.heal(99999.0)
		health_changed.emit(health.current_health)

func _on_health_updated(current: float, max_hp: float) -> void:
	if overhead_health_bar != null:
		overhead_health_bar.max_value = max_hp
		overhead_health_bar.value = current
	health_changed.emit(current)

func perform_attack() -> void:
	if is_dead:
		return
	is_attacking = true
	if weapon_sprite != null:
		weapon_sprite.show()
	
	if animation_player != null and animation_player.has_animation("attack"):
		animation_player.play("attack")

	if sword_collision != null:
		sword_collision.disabled = false
	await get_tree().create_timer(0.1).timeout
	
	var damage_amount: float = stats.get_stat("physical_damage") if stats != null else 10.0
	if sword_area != null:
		var bodies: Array[Node2D] = sword_area.get_overlapping_bodies()
		for body: Node2D in bodies:
			if body != self and body.has_method("take_damage"):
				var data: DamageData = DamageData.new(damage_amount, self, GameEnums.DamageType.PHYSICAL)
				body.call("take_damage", data)
	
	if sword_collision != null:
		sword_collision.disabled = true
	if weapon_sprite != null:
		weapon_sprite.hide()
	await get_tree().create_timer(0.3).timeout
	is_attacking = false
