extends Node
class_name HealthComponent

# --- СИГНАЛИ ---
signal health_changed(current_hp, max_hp)
signal died

# --- ЗВ'ЯЗКИ ---
@export var stats_component: StatsComponent

var current_health: float

func _ready():
	# Чекаємо кадр, щоб StatsComponent встиг завантажитись
	await get_tree().process_frame
	
	if stats_component:
		initialize_health()
	else:
		push_error("HealthComponent: Помилка! Не призначено StatsComponent!")

# Функція стартового налаштування (або повного відновлення)
func initialize_health():
	if not stats_component: return
	
	var max_hp = stats_component.get_stat("max_health")
	current_health = max_hp
	health_changed.emit(current_health, max_hp)

# --- ОТРИМАННЯ ШКОДИ ---
func take_damage(data: DamageData):
	# --- ГОЛОВНА ЗМІНА: ПІДКЛЮЧЕННЯ БУХГАЛТЕРІЇ ---
	# Ми не просто віднімаємо data.amount.
	# Ми просимо DamageSystem порахувати фінальну шкоду (враховуючи броню).
	var final_damage = DamageSystem.apply_defense(data, stats_component)
	# -----------------------------------------------
	
	current_health -= final_damage
	
	# Оновлюємо UI
	var max_hp = stats_component.get_stat("max_health")
	health_changed.emit(current_health, max_hp)
	
	# Лог для перевірки роботи броні
	if data.source:
		print("Отримав ", final_damage, " шкоди (вхідна: ", data.amount, ") від ", data.source.name)
	
	# Перевірка на смерть
	if current_health <= 0:
		died.emit()

# --- ЛІКУВАННЯ ---
func heal(amount: float):
	if not stats_component: return
	
	var max_hp = stats_component.get_stat("max_health")
	current_health += amount
	
	# Не дозволяємо лікувати більше максимуму
	if current_health > max_hp:
		current_health = max_hp
		
	health_changed.emit(current_health, max_hp)
