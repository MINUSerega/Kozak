extends Resource
class_name PlayerData

# --- 1. ФІЗИКА РУХУ (Платформер) ---
@export_group("Movement Physics")
@export var speed: float = 200.0
@export var acceleration: float = 1000.0 # Як швидко розганяється
@export var friction: float = 1000.0     # Як швидко зупиняється

# --- 2. НАЛАШТУВАННЯ СТРИБКА (Advanced Jump) ---
# Це математика для "приємного" стрибка, як в Mario/Celeste
@export_group("Jump Physics")
@export var jump_height: float = 120.0     # Висота (пікселі)
@export var jump_time_to_peak: float = 0.35 # Час зльоту (сек)
@export var jump_time_to_descent: float = 0.3 # Час падіння (сек) - менше = різкіше

# --- 3. RPG ХАРАКТЕРИСТИКИ ---
# Сюди ми вкладемо наш AttributeData (Сила, Спритність...)
@export_group("RPG Stats")
@export var base_stats: AttributeData

# --- ДОПОМІЖНІ ЗМІННІ (Рахуються автоматично) ---
# Тобі не треба їх чіпати в інспекторі, код порахує їх сам
var jump_velocity: float = 0.0
var jump_gravity: float = 0.0
var fall_gravity: float = 0.0

# Функція для розрахунку фізики (викликається гравцем на старті)
func calculate_physics():
	# Формула: g = (2 * h) / t^2
	jump_gravity = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	fall_gravity = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)
	
	# Формула: v = -sqrt(2 * g * h) або просто -g * t
	jump_velocity = -1.0 * jump_gravity * jump_time_to_peak
