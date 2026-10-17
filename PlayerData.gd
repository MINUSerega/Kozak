extends Resource
class_name PlayerData

@export_group("Movement Physics")
## Базова швидкість руху гравця (якщо не перевизначена у StatsComponent)
@export var speed: float = 220.0
## Швидкість набору максимальної швидкості
@export var acceleration: float = 1400.0
## Сила гальмування при зупинці
@export var friction: float = 1600.0
## Гравітація для надійного утримання персонажа на лінії землі Y = 0
@export var gravity_force: float = 1200.0

@export_group("Legacy Jump Compatibility")
## Залишено для зворотної сумісності зі збереженим файлом DefaultPlayerData.tres
@export var jump_height: float = 0.0
@export var jump_time_to_peak: float = 0.35
@export var jump_time_to_descent: float = 0.3

@export_group("RPG Stats")
## Базові RPG характеристики гравця
@export var base_stats: AttributeData

# Поля сумісності
var jump_velocity: float = 0.0
var jump_gravity: float = 1200.0
var fall_gravity: float = 1200.0

## Ініціалізація параметрів фізики на старті (стрибки вимкнено)
func calculate_physics() -> void:
	jump_velocity = 0.0
	jump_gravity = maxf(gravity_force, 980.0)
	fall_gravity = maxf(gravity_force, 980.0)