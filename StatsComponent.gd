extends Node
class_name StatsComponent

## Сигнал про зміну будь-якої характеристики (для UI та HealthComponent)
signal stats_recalculated

@export var base_attributes: AttributeData

# Кеш базових значень характеристик: { String: float }
var current_stats: Dictionary = {}

# Словник модифікаторів від екіпірування, бафів та Кодексу: { stat_name: { source_id: float } }
var modifiers: Dictionary = {}

func _ready() -> void:
	if base_attributes == null:
		base_attributes = AttributeData.new()
	_recalculate_stats()

## Перерахунок базового кешу характеристик із ресурсу AttributeData
func _recalculate_stats() -> void:
	if base_attributes == null:
		return
	
	# 1. Первинні атрибути
	current_stats["strength"] = maxf(0.0, base_attributes.strength)
	current_stats["dexterity"] = maxf(0.0, base_attributes.dexterity)
	current_stats["intelligence"] = maxf(0.0, base_attributes.intelligence)
	current_stats["constitution"] = maxf(0.0, base_attributes.constitution)
	current_stats["luck"] = maxf(0.0, base_attributes.luck)
	
	# 2. Життєві показники
	current_stats["base_max_health"] = maxf(1.0, base_attributes.max_health)
	current_stats["health_regeneration"] = maxf(0.0, base_attributes.health_regeneration)
	current_stats["max_mana"] = maxf(0.0, base_attributes.max_mana)
	current_stats["mana_regeneration"] = maxf(0.0, base_attributes.mana_regeneration)
	
	# 3. Атака
	current_stats["physical_damage"] = maxf(0.0, base_attributes.physical_damage)
	current_stats["magic_damage"] = maxf(0.0, base_attributes.magic_damage)
	current_stats["attack_speed"] = maxf(0.1, base_attributes.attack_speed)
	current_stats["attack_range"] = maxf(10.0, base_attributes.attack_range)
	current_stats["critical_chance"] = clampf(base_attributes.critical_chance, 0.0, 1.0)
	current_stats["critical_multiplier"] = maxf(1.0, base_attributes.critical_multiplier)
	current_stats["life_steal"] = clampf(base_attributes.life_steal, 0.0, 1.0)
	current_stats["cooldown_reduction"] = clampf(base_attributes.cooldown_reduction, 0.0, 0.8)
	
	# 4. Захист
	current_stats["armor"] = maxf(0.0, base_attributes.armor)
	current_stats["magic_resistance"] = clampf(base_attributes.magic_resistance, 0.0, 0.95)
	current_stats["evasion"] = clampf(base_attributes.evasion, 0.0, 0.90)
	current_stats["block_chance"] = clampf(base_attributes.block_chance, 0.0, 0.90)
	current_stats["crowd_control_reduction"] = clampf(base_attributes.crowd_control_reduction, 0.0, 0.90)
	current_stats["thorns"] = maxf(0.0, base_attributes.thorns)
	
	# 5. Рух та економіка
	current_stats["movement_speed"] = maxf(10.0, base_attributes.movement_speed)
	current_stats["xp_reward"] = float(maxi(0, base_attributes.xp_reward))
	current_stats["gold_find"] = maxf(0.0, base_attributes.gold_find)
	current_stats["magic_find"] = maxf(0.0, base_attributes.magic_find)
	
	stats_recalculated.emit()

## Додавання бонусу до характеристики від конкретного джерела (предмет, заточка, Кодекс)
func add_modifier(stat_name: String, source_id: String, value: float) -> void:
	if stat_name.is_empty() or source_id.is_empty() or is_nan(value) or is_inf(value):
		return
	if not modifiers.has(stat_name):
		modifiers[stat_name] = {}
	var source_dict: Dictionary = modifiers[stat_name] as Dictionary
	source_dict[source_id] = value
	stats_recalculated.emit()

## Видалення бонусу характеристики за ідентифікатором джерела
func remove_modifier(stat_name: String, source_id: String) -> void:
	if modifiers.has(stat_name):
		var source_dict: Dictionary = modifiers[stat_name] as Dictionary
		source_dict.erase(source_id)
		stats_recalculated.emit()

## Очищення всіх бонусів від конкретного джерела (наприклад, при знятті предмета)
func remove_all_modifiers_from_source(source_id: String) -> void:
	for stat_key: Variant in modifiers.keys():
		var stat_name: String = str(stat_key)
		var source_dict: Dictionary = modifiers[stat_name] as Dictionary
		if source_dict.has(source_id):
			source_dict.erase(source_id)
	stats_recalculated.emit()

## Отримання фінального значення характеристики з урахуванням атрибутів та бонусів
func get_stat(stat_name: String) -> float:
	var val: float = float(current_stats.get(stat_name, 0.0))
	
	match stat_name:
		"max_health":
			var constitution: float = get_stat("constitution")
			val = float(current_stats.get("base_max_health", 100.0)) + (constitution * 10.0)
		"physical_damage":
			var strength: float = get_stat("strength")
			val += strength * 2.0
		"magic_damage":
			var intelligence: float = get_stat("intelligence")
			val += intelligence * 2.0
		"max_mana":
			var intelligence: float = get_stat("intelligence")
			val += intelligence * 5.0
		"critical_chance":
			var dexterity: float = get_stat("dexterity")
			val += dexterity * 0.005
		"evasion":
			var dexterity: float = get_stat("dexterity")
			val += dexterity * 0.005

	if modifiers.has(stat_name):
		var source_dict: Dictionary = modifiers[stat_name] as Dictionary
		for source_key: Variant in source_dict.keys():
			val += float(source_dict[source_key])
			
	return maxf(0.0, val)