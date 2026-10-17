extends Node
class_name HealthComponent

## Сигнал зміни здоров'я (передає поточне та максимальне значення)
signal health_changed(current_hp: float, max_hp: float)
## Сигнал смерті сутності
signal died

@export var stats_component: StatsComponent

var current_health: float = 100.0

func _ready() -> void:
	await get_tree().process_frame
	
	if stats_component != null:
		initialize_health()
	else:
		push_error("HealthComponent: Не призначено StatsComponent!")

## Повне відновлення та ініціалізація здоров'я
func initialize_health() -> void:
	if stats_component == null:
		return
	
	var max_hp: float = maxf(1.0, stats_component.get_stat("max_health"))
	current_health = max_hp
	health_changed.emit(current_health, max_hp)

## Отримання шкоди з урахуванням броні та валідацією значень
func take_damage(data: DamageData) -> void:
	if data == null or current_health <= 0.0:
		return
		
	var final_damage: int = DamageSystem.apply_defense(data, stats_component)
	var validated_damage: float = maxf(0.0, float(final_damage))
	
	current_health = maxf(0.0, current_health - validated_damage)
	
	var max_hp: float = stats_component.get_stat("max_health") if stats_component != null else 100.0
	health_changed.emit(current_health, max_hp)
	
	if current_health <= 0.0:
		died.emit()

## Лікування сутності з обмеженням до максимального запасу здоров'я
func heal(amount: float) -> void:
	if stats_component == null or amount <= 0.0 or is_nan(amount):
		return
	
	var max_hp: float = maxf(1.0, stats_component.get_stat("max_health"))
	current_health = clampf(current_health + amount, 0.0, max_hp)
	health_changed.emit(current_health, max_hp)