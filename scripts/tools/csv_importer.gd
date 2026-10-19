@tool
extends EditorScript

## Шлях до вихідного CSV файлу з таблиці
const CSV_PATH: String = "res://data/source/monsters.csv"
## Шлях для збереження згенерованих файлів бази даних
const OUT_PATH: String = "res://data/monsters/"

func _run() -> void:
	print("--- ПОЧАТОК ІМПОРТУ БАЗИ МОНСТРІВ ---")
	
	if not FileAccess.file_exists(CSV_PATH):
		push_error("Помилка: Файл не знайдено за шляхом " + CSV_PATH)
		return
		
	if not DirAccess.dir_exists_absolute(OUT_PATH):
		DirAccess.make_dir_recursive_absolute(OUT_PATH)
		
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("Помилка: Не вдалося відкрити файл CSV.")
		return
		
	# Автовизначення роздільника (кома або крапка з комою для української локалі)
	var first_line_text: String = file.get_line()
	var delim: String = ";" if first_line_text.contains(";") else ","
	file.seek(0)
	
	var headers: PackedStringArray = file.get_csv_line(delim)
	var generated_count: int = 0
	
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line(delim)
		
		if row.size() < headers.size() or row[0].is_empty():
			continue
			
		var mob_id: String = row[0].strip_edges()
		
		var monster: MonsterData = MonsterData.new()
		var attributes: AttributeData = AttributeData.new()
		
		monster.id = mob_id
		monster.monster_name = row[1].strip_edges()
		monster.level = row[2].to_int()
		monster.is_aggressive = (row[3].strip_edges().to_lower() == "true")
		monster.xp_reward = row[4].to_int()
		
		attributes.strength = row[5].to_float()
		attributes.max_health = row[6].to_float()
		# Передаємо дефолтні значення для AI, якщо їх немає в таблиці
		attributes.detection_radius = 200.0
		attributes.chase_limit = 400.0
		attributes.attack_range = 40.0
		attributes.movement_speed = 60.0
		
		monster.base_attributes = attributes
		
		var drops_raw: String = row[7].strip_edges()
		var drops_dict: Dictionary = {}
		
		if not drops_raw.is_empty():
			var drop_entries: PackedStringArray = drops_raw.split("|", false)
			for entry: String in drop_entries:
				var drop_parts: PackedStringArray = entry.split(":")
				if drop_parts.size() >= 4:
					var item_id: String = drop_parts[0].strip_edges()
					var drop_info: Dictionary = {
						"chance": drop_parts[1].to_float(),
						"min": drop_parts[2].to_int(),
						"max": drop_parts[3].to_int()
					}
					drops_dict[item_id] = drop_info
					
		monster.drops = drops_dict
		
		var save_path: String = OUT_PATH + mob_id + ".tres"
		var error: int = ResourceSaver.save(monster, save_path)
		
		if error == OK:
			generated_count += 1
		else:
			push_error("Помилка збереження ресурсу для " + mob_id)
			
	file.close()
	print("--- УСПІШНО! Згенеровано монстрів: ", generated_count, " ---")
