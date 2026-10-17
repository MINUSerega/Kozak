extends Node

# [ВАЖЛИВО] Цей рядок вказує шлях до папки з предметами.
const ITEMS_PATH = "res://items/loot/"

var MOBS = {
	"e0001": {
		"name": "Weak Gremlin",
		"level": 1,
		"is_aggressive": true,
		"skills": ["s0001"],
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
			"respawn_time": 5.0,
		},
		# ДРОП: Тепер це словник з налаштуваннями
		"drops": {
			"skin": { 
				"chance": 0.9,  # 90% шанс
				"min": 1,       # Мінімум 1
				"max": 5        # Максимум 5
			},
			"rusty_sword": { 
				"chance": 0.2, 
				"min": 1, 
				"max": 1
			}
		}
	},
	"e0002": {
		"name": "Forest Orc",
		"level": 5,
		"is_aggressive": true,
		"skills": ["s0001", "s0005"],
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
			"skin": { 
				"chance": 0.5, 
				"min": 1, 
				"max": 3 
			},
			"rusty_sword": { 
				"chance": 0.2, 
				"min": 1, 
				"max": 1 
			},
			# Не забудь створити файл coin.tres в папці loot!
			"coin": { 
				"chance": 1.0, 
				"min": 1, 
				"max": 5 
			}
		}
	}
}

func get_attributes(mob_id: String) -> AttributeData:
	if not MOBS.has(mob_id):
		push_error("MonsterDB: ID не знайдено -> " + mob_id)
		return AttributeData.new()

	var data = MOBS[mob_id]
	var stats_data = data.get("stats", {}) 

	var attrs = AttributeData.new()
	
	# --- ПЕРВИННІ ---
	attrs.strength = stats_data.get("strength", 10.0)
	attrs.dexterity = stats_data.get("dexterity", 10.0)
	attrs.intelligence = stats_data.get("intelligence", 10.0)
	attrs.constitution = stats_data.get("constitution", 10.0)
	attrs.luck = stats_data.get("luck", 5.0)
	
	# --- ЖИТТЄВІ ПОКАЗНИКИ ---
	if stats_data.has("max_health"):
		attrs.max_health = stats_data.get("max_health", 100.0)
	elif stats_data.has("base_health"):
		attrs.max_health = stats_data.get("base_health", 100.0)
		
	attrs.health_regeneration = stats_data.get("health_regeneration", 1.0)
	attrs.max_mana = stats_data.get("max_mana", 50.0)
	attrs.mana_regeneration = stats_data.get("mana_regeneration", 2.0)
	
	# --- БОЙОВІ ---
	attrs.armor = stats_data.get("armor", 0.0)
	attrs.physical_damage = stats_data.get("physical_damage", 10.0)
	attrs.magic_damage = stats_data.get("magic_damage", 0.0)
	attrs.movement_speed = stats_data.get("movement_speed", 150.0)
	attrs.attack_range = stats_data.get("attack_range", 40.0)
	attrs.attack_speed = stats_data.get("attack_speed", 1.0)
	
	# Крити та інше
	attrs.critical_chance = stats_data.get("critical_chance", 0.05)
	attrs.critical_multiplier = stats_data.get("critical_multiplier", 1.5)
	
	# --- AI ПАРАМЕТРИ ---
	attrs.detection_radius = stats_data.get("detection_radius", 200.0)
	attrs.chase_limit = stats_data.get("chase_limit", 400.0)
	attrs.wander_radius = stats_data.get("wander_radius", 100.0)
	attrs.respawn_time = stats_data.get("respawn_time", 15.0)
	
	# --- НАГОРОДИ ---
	attrs.xp_reward = data.get("xp_reward", 10)
	
	return attrs

func get_mob_info(mob_id: String) -> Dictionary:
	return MOBS.get(mob_id, {})
	
# [НОВА ФУНКЦІЯ] Розрахунок випадіння предметів
func calculate_loot(mob_id: String) -> Array[ItemData]:
	var dropped_items: Array[ItemData] = []
	
	if not MOBS.has(mob_id): return []
	
	var mob_data = MOBS[mob_id]
	# Отримуємо таблицю дропу (завжди словник)
	var drop_table = mob_data.get("drops", {})
	
	for item_id in drop_table:
		var entry = drop_table[item_id]
		
		# Змінні за замовчуванням
		var chance = 0.0
		var min_qty = 1
		var max_qty = 1
		
		# Перевіряємо формат: Словник чи просте число
		if entry is Dictionary:
			chance = entry.get("chance", 0.0)
			min_qty = entry.get("min", 1)
			max_qty = entry.get("max", 1)
		elif entry is float:
			chance = entry # Старий формат
		
		# Кидаємо кубик (шанс)
		if randf() <= chance:
			var path = ITEMS_PATH + item_id + ".tres"
			
			if ResourceLoader.exists(path):
				var item_res = load(path) as ItemData
				
				# [ВАЖЛИВО] Створюємо унікальну копію предмета
				var new_item = item_res.duplicate()
				
				# [ВАЖЛИВО] Генеруємо випадкову кількість від Min до Max
				# Ця цифра зберігається всередині new_item і передається гравцю
				new_item.quantity = randi_range(min_qty, max_qty)
				
				dropped_items.append(new_item) 
			else:
				print("ПОМИЛКА: Не знайдено файл предмета: ", path)
				
	return dropped_items
