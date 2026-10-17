extends Node
class_name StatsComponent

@export var base_attributes: AttributeData

# Кеш для поточних значень (база)
var current_stats: Dictionary = {}

# [НОВЕ] Словник для бонусів від предметів/бафів
# Структура: { "stat_name": { "source_id": value } }
# Наприклад: { "movement_speed": { "boots_of_speed": 20.0, "potion": 10.0 } }
var modifiers: Dictionary = {}

func _ready():
	if not base_attributes:
		base_attributes = AttributeData.new()
	_recalculate_stats()

func _recalculate_stats():
	if not base_attributes: return
	
	# --- 1. Копіюємо ПЕРВИННІ атрибути ---
	current_stats["strength"] = base_attributes.strength
	current_stats["dexterity"] = base_attributes.dexterity
	current_stats["intelligence"] = base_attributes.intelligence
	current_stats["constitution"] = base_attributes.constitution
	current_stats["luck"] = base_attributes.luck
	
	# --- 2. Копіюємо ЖИТТЄВІ показники ---
	current_stats["base_max_health"] = base_attributes.max_health 
	current_stats["health_regeneration"] = base_attributes.health_regeneration
	current_stats["max_mana"] = base_attributes.max_mana
	current_stats["mana_regeneration"] = base_attributes.mana_regeneration
	
	# --- 3. Копіюємо АТАКУ ---
	current_stats["physical_damage"] = base_attributes.physical_damage
	current_stats["magic_damage"] = base_attributes.magic_damage
	current_stats["attack_speed"] = base_attributes.attack_speed
	current_stats["attack_range"] = base_attributes.attack_range
	current_stats["critical_chance"] = base_attributes.critical_chance
	current_stats["critical_multiplier"] = base_attributes.critical_multiplier
	current_stats["life_steal"] = base_attributes.life_steal
	current_stats["cooldown_reduction"] = base_attributes.cooldown_reduction
	
	# --- 4. Копіюємо ЗАХИСТ ---
	current_stats["armor"] = base_attributes.armor
	current_stats["magic_resistance"] = base_attributes.magic_resistance
	current_stats["evasion"] = base_attributes.evasion
	current_stats["block_chance"] = base_attributes.block_chance
	current_stats["crowd_control_reduction"] = base_attributes.crowd_control_reduction
	current_stats["thorns"] = base_attributes.thorns
	
	# --- 5. Копіюємо РУХ та ІНШЕ ---
	current_stats["movement_speed"] = base_attributes.movement_speed
	current_stats["xp_reward"] = base_attributes.xp_reward
	current_stats["gold_find"] = base_attributes.gold_find
	current_stats["magic_find"] = base_attributes.magic_find

# [НОВЕ] Функції для додавання/видалення бонусів
func add_modifier(stat_name: String, source_id: String, value: float):
	if not modifiers.has(stat_name):
		modifiers[stat_name] = {}
	modifiers[stat_name][source_id] = value
	# Наприклад: add_modifier("movement_speed", "boots_lvl1", 50.0)

func remove_modifier(stat_name: String, source_id: String):
	if modifiers.has(stat_name):
		modifiers[stat_name].erase(source_id)

func get_stat(stat_name: String) -> float:
	# 1. Беремо базове значення
	var val = current_stats.get(stat_name, 0.0)
	
	# 2. Застосовуємо формули атрибутів
	match stat_name:
		"max_health":
			var constitution = get_stat("constitution") # Рекурсія врахує бонуси до конституції
			val = current_stats["base_max_health"] + (constitution * 10.0)
		"physical_damage":
			var strength = get_stat("strength")
			val = val + (strength * 2.0)
		"magic_damage":
			var intelligence = get_stat("intelligence")
			val = val + (intelligence * 2.0)
		"max_mana":
			var intelligence = get_stat("intelligence")
			val = val + (intelligence * 5.0)
		"critical_chance":
			var dexterity = get_stat("dexterity")
			val = val + (dexterity * 0.005)
		"evasion":
			var dexterity = get_stat("dexterity")
			val = val + (dexterity * 0.005)

	# 3. [НОВЕ] Додаємо всі бонуси від предметів (Modifiers)
	if modifiers.has(stat_name):
		for source in modifiers[stat_name]:
			val += modifiers[stat_name][source]
			
	return val
