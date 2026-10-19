extends Node

const ITEMS_PATH: String = "res://items/loot/"
const MONSTERS_PATH: String = "res://data/monsters/"

var _loaded_monsters: Dictionary = {}

func _ready() -> void:
	_cache_all_monsters()

## Сканує папку і безпечно завантажує файли в ОЗП
func _cache_all_monsters() -> void:
	if not DirAccess.dir_exists_absolute(MONSTERS_PATH):
		DirAccess.make_dir_recursive_absolute(MONSTERS_PATH)
		push_error("MonsterDB: Папки не існувало! Натисни Ctrl+Shift+X у csv_importer.gd")
		return
		
	var files: PackedStringArray = DirAccess.get_files_at(MONSTERS_PATH)
	for file_name: String in files:
		if file_name.ends_with(".tres") or file_name.ends_with(".res") or file_name.ends_with(".remap"):
			var clean_name: String = file_name.replace(".remap", "")
			var full_path: String = MONSTERS_PATH + clean_name
			var res: Resource = load(full_path)
			
			# [ОБХІД БАГА GODOT] "is MonsterData" в Autoload часто хибно видає false.
			# Перевіряємо наявність властивості "id" безпосередньо (Duck Typing).
			if res != null and res.get("id") != null:
				var actual_id: String = str(res.get("id"))
				if actual_id.is_empty():
					actual_id = clean_name.get_basename()
				_loaded_monsters[actual_id] = res
				
	if _loaded_monsters.is_empty():
		push_error("MonsterDB: ❌ КРИТИЧНА ПОМИЛКА! БАЗА ПОРОЖНЯ! Вороги будуть сліпі і без дропу!")
	else:
		print("MonsterDB: ✅ Успішно завантажено мобів: ", _loaded_monsters.size())

## Отримання характеристик моба
func get_attributes(mob_id: String) -> AttributeData:
	if not _loaded_monsters.has(mob_id):
		return AttributeData.new()
		
	var data: Resource = _loaded_monsters[mob_id]
	var attrs: Variant = data.get("base_attributes")
	if attrs != null and attrs is AttributeData:
		return attrs.duplicate() as AttributeData
		
	return AttributeData.new()

## Отримання інформації для UI та логіки
func get_mob_info(mob_id: String) -> Dictionary:
	if not _loaded_monsters.has(mob_id):
		return {}
		
	var data: Resource = _loaded_monsters[mob_id]
	return {
		"name": str(data.get("monster_name")),
		"level": int(data.get("level")),
		"is_aggressive": bool(data.get("is_aggressive")),
		"xp_reward": int(data.get("xp_reward"))
	}

## Безпечний розрахунок луту з обходом кешу ResourceLoader
func calculate_loot(mob_id: String) -> Array[ItemData]:
	var dropped_items: Array[ItemData] = []
	
	if not _loaded_monsters.has(mob_id):
		return dropped_items
		
	var data: Resource = _loaded_monsters[mob_id]
	var drop_table: Variant = data.get("drops")
	
	if drop_table == null or typeof(drop_table) != TYPE_DICTIONARY:
		return dropped_items
		
	var drops_dict: Dictionary = drop_table as Dictionary
	
	for item_key: Variant in drops_dict.keys():
		var item_id: String = str(item_key)
		var entry: Variant = drops_dict[item_id]
		
		var chance: float = 0.0
		var min_qty: int = 1
		var max_qty: int = 1
		
		if entry is Dictionary:
			var entry_dict: Dictionary = entry as Dictionary
			chance = float(entry_dict.get("chance", 0.0))
			min_qty = int(entry_dict.get("min", 1))
			max_qty = int(entry_dict.get("max", 1))
			
		if randf() <= chance:
			var path: String = ITEMS_PATH + item_id + ".tres"
			
			# [ОБХІД БАГА GODOT] Пряме завантаження замість ResourceLoader.exists()
			var item_res: Resource = load(path)
			if item_res != null and item_res is ItemData:
				var new_item: ItemData = item_res.duplicate() as ItemData
				new_item.quantity = randi_range(min_qty, max_qty)
				dropped_items.append(new_item)
			else:
				push_error("MonsterDB: ❌ ПОМИЛКА ДРОПУ! Не знайдено предмет: " + path)
				
	return dropped_items
