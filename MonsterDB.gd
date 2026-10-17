extends Node

# [ВАЖЛИВО] Шлях до папки з предметами екіпірування та лутом
const ITEMS_PATH: String = "res://items/loot/"

# База даних усіх монстрів у грі.
# Використовуються нові строкові ID (enm_0001, enm_0002 тощо).
var MOBS: Dictionary = {
	"enm_0001": {
		"name": "Weak Gremlin",
		"level": 1,
		"is_aggressive": true,
		"skills": ["skl_0001"],
		"xp_reward": 15,
		"stats": {
			"strength": 5.0,
			"max_health": 5.0,
			"dexterity": 5.0,
			"intelligence": 5.0,
			"armor": 0.0,
			"movement_speed": 130.0,
			"attack_range": 40.0,
			"attack_speed": 1.2,
			"detection_radius": 500.0,
			"chase_limit": 700.0,
			"wander_radius": 300.0,
			"respawn_time": 5.0
		},
		"drops": {
			# res_0001 - це колишня шкіра (skin)
			"res_0001": { 
				"chance": 0.9, 
				"min": 1, 
				"max": 5 
			},
			# wpn_0001 - це колишній іржавий меч (rusty_sword)
			"wpn_0001": { 
				"chance": 0.2, 
				"min": 1, 
				"max": 1 
			}
		}
	},
	"enm_0002": {
		"name": "Forest Orc",
		"level": 5,
		"is_aggressive": true,
		"skills": ["skl_0001", "skl_0005"],
		"xp_reward": 100,
		"stats": {
			"strength": 15.0,
			"max_health": 12.0,
			"dexterity": 8.0,
			"intelligence": 5.0,
			"armor": 2.0,
			"movement_speed": 70.0,
			"attack_range": 45.0,
			"attack_speed": 1.0,
			"detection_radius": 250.0,
			"chase_limit": 500.0,
			"wander_radius": 150.0,
			"respawn_time": 10.0
		},
		"drops": {
			# res_0001 - Шкіра
			"res_0001": { 
				"chance": 0.5, 
				"min": 1, 
				"max": 3 
			},
			# wpn_0001 - Іржавий меч
			"wpn_0001": { 
				"chance": 0.2, 
				"min": 1, 
				"max": 1 
			},
			# res_0002 - Монета (coin)
			"res_0002": { 
				"chance": 1.0, 
				"min": 1, 
				"max": 5 
			}
		}
	}
}

## Отримання базових характеристик для моба за його ID
func get_attributes(mob_id: String) -> AttributeData:
	if not MOBS.has(mob_id):
		push_error("MonsterDB: ID моба не знайдено -> " + mob_id)
		return AttributeData.new()

	var data: Dictionary = MOBS[mob_id] as Dictionary
	var stats_data: Dictionary = data.get("stats", {}) as Dictionary

	var attrs: AttributeData = AttributeData.new()
	
	# Первинні атрибути
	attrs.strength = float(stats_data.get("strength", 10.0))
	attrs.dexterity = float(stats_data.get("dexterity", 10.0))
	attrs.intelligence = float(stats_data.get("intelligence", 10.0))
	attrs.constitution = float(stats_data.get("constitution", 10.0))
	attrs.luck = float(stats_data.get("luck", 5.0))
	
	# Життєві показники
	if stats_data.has("max_health"):
		attrs.max_health = float(stats_data.get("max_health", 100.0))
	elif stats_data.has("base_health"):
		attrs.max_health = float(stats_data.get("base_health", 100.0))
		
	attrs.health_regeneration = float(stats_data.get("health_regeneration", 1.0))
	attrs.max_mana = float(stats_data.get("max_mana", 50.0))
	attrs.mana_regeneration = float(stats_data.get("mana_regeneration", 2.0))
	
	# Бойові характеристики
	attrs.armor = float(stats_data.get("armor", 0.0))
	attrs.physical_damage = float(stats_data.get("physical_damage", 10.0))
	attrs.magic_damage = float(stats_data.get("magic_damage", 0.0))
	attrs.movement_speed = float(stats_data.get("movement_speed", 150.0))
	attrs.attack_range = float(stats_data.get("attack_range", 40.0))
	attrs.attack_speed = float(stats_data.get("attack_speed", 1.0))
	
	attrs.critical_chance = float(stats_data.get("critical_chance", 0.05))
	attrs.critical_multiplier = float(stats_data.get("critical_multiplier", 1.5))
	
	# AI параметри поведінки
	attrs.detection_radius = float(stats_data.get("detection_radius", 200.0))
	attrs.chase_limit = float(stats_data.get("chase_limit", 400.0))
	attrs.wander_radius = float(stats_data.get("wander_radius", 100.0))
	attrs.respawn_time = float(stats_data.get("respawn_time", 15.0))
	
	# Нагороди
	attrs.xp_reward = int(data.get("xp_reward", 10))
	
	return attrs

## Отримання словника з інформацією про моба
func get_mob_info(mob_id: String) -> Dictionary:
	return MOBS.get(mob_id, {}) as Dictionary
	
## Розрахунок випадіння предметів при смерті моба
func calculate_loot(mob_id: String) -> Array[ItemData]:
	var dropped_items: Array[ItemData] = []
	
	if not MOBS.has(mob_id): 
		return dropped_items
	
	var mob_data: Dictionary = MOBS[mob_id] as Dictionary
	var drop_table: Dictionary = mob_data.get("drops", {}) as Dictionary
	
	for item_key: Variant in drop_table.keys():
		var item_id: String = str(item_key)
		var entry: Variant = drop_table[item_id]
		
		var chance: float = 0.0
		var min_qty: int = 1
		var max_qty: int = 1
		
		if entry is Dictionary:
			var entry_dict: Dictionary = entry as Dictionary
			chance = float(entry_dict.get("chance", 0.0))
			min_qty = int(entry_dict.get("min", 1))
			max_qty = int(entry_dict.get("max", 1))
		elif entry is float or entry is int:
			chance = float(entry)
		
		if randf() <= chance:
			var path: String = ITEMS_PATH + item_id + ".tres"
			
			if ResourceLoader.exists(path):
				var item_res: Resource = load(path)
				if item_res is ItemData:
					var new_item: ItemData = item_res.duplicate() as ItemData
					new_item.quantity = randi_range(min_qty, max_qty)
					dropped_items.append(new_item)
			else:
				print("MonsterDB: ПОМИЛКА! Не знайдено файл предмета луту -> ", path)
				
	return dropped_items