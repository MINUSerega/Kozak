extends Resource
class_name AttributeData

# ==========================================
# ПЕРВИННІ АТРИБУТИ (Primary Attributes)
# Впливають на інші характеристики
# ==========================================
@export_group("Primary Attributes")
@export var strength: float = 10.0      # Сила (Фіз. шкода + вантажопідйомність)
@export var dexterity: float = 10.0     # Спритність (Швидкість, крит, ухилення)
@export var intelligence: float = 10.0  # Інтелект (Мана, маг. шкода, реген мани)
@export var constitution: float = 10.0  # Витривалість/Тілобудова (Макс. ХП + реген ХП)
@export var luck: float = 5.0           # Удача (Дроп, рідкісні події)

# ==========================================
# ЖИТТЄВІ ПОКАЗНИКИ (Vitals)
# Ресурси для виживання та скілів
# ==========================================
@export_group("Vitals")
@export var max_health: float = 100.0        # Максимальне здоров'я (раніше base_health)
@export var health_regeneration: float = 1.0 # Регенерація здоров'я (ХП за секунду)
@export var max_mana: float = 50.0           # Максимальна мана/енергія
@export var mana_regeneration: float = 2.0   # Швидкість відновлення мани

# ==========================================
# АТАКА ТА ШКОДА (Offensive Stats)
# Параметри для нанесення урону
# ==========================================
@export_group("Offense")
@export var physical_damage: float = 10.0    # Базова фізична шкода
@export var magic_damage: float = 0.0        # Магічна сила
@export var attack_speed: float = 1.0        # Швидкість атаки (множник анімації)
@export var attack_range: float = 40.0       # Радіус атаки (для ближнього бою)

@export_subgroup("Criticals")
@export_range(0, 1) var critical_chance: float = 0.05    # Шанс криту (0.05 = 5%)
@export var critical_multiplier: float = 1.5             # Сила криту (1.5x від норми)

@export_subgroup("Special Effects")
@export_range(0, 1) var life_steal: float = 0.0          # Вампіризм (0.1 = 10% від шкоди повертається в ХП)
@export_range(0, 1) var cooldown_reduction: float = 0.0  # Зменшення перезарядки скілів (0.1 = -10% часу)

# ==========================================
# ЗАХИСТ (Defensive Stats)
# Зменшення вхідної шкоди
# ==========================================
@export_group("Defense")
@export var armor: float = 0.0               # Фізична броня (пряме зменшення або формульне)
@export_range(0, 1) var magic_resistance: float = 0.0    # Магічний опір (0.2 = 20% ігнорування маг. шкоди)
@export_range(0, 1) var evasion: float = 0.0             # Ухилення (шанс уникнути удару повністю)
@export_range(0, 1) var block_chance: float = 0.0        # Шанс блоку щитом
@export_range(0, 1) var crowd_control_reduction: float = 0.0 # Стійкість (зменшення часу станів)
@export_range(0, 1) var thorns: float = 0.0              # Шипи (повернення % шкоди ворогу)

# ==========================================
# РУХ (Mobility)
# Фізика пересування
# ==========================================
@export_group("Mobility")
@export var movement_speed: float = 200.0    # Швидкість руху (пікселів/сек)

# ==========================================
# ЕКОНОМІКА ТА ПРОГРЕС (Rewards & Loot)
# ==========================================
@export_group("Rewards & Progress")
# Для Гравця:
@export var gold_find: float = 1.0           # Множник золота (1.0 = 100%, 1.5 = +50%)
@export var magic_find: float = 1.0          # Шанс знайти магічні речі
@export var experience_gain: float = 1.0     # Множник отримання досвіду

# Для Монстрів (скільки дають при вбивстві):
@export var xp_reward: int = 10              # Скільки досвіду дає цей монстр

# ==========================================
# ШТУЧНИЙ ІНТЕЛЕКТ (AI Logic)
# Тільки для монстрів
# ==========================================
@export_group("AI Parameters")
@export var detection_radius: float = 200.0  # Радіус виявлення гравця
@export var chase_limit: float = 400.0       # Як далеко монстр може гнатися
@export var wander_radius: float = 100.0     # Радіус патрулювання
@export var respawn_time: float = 15.0       # Час до відродження

# ==========================================
# ВАЛЮТА (Currency)
# ==========================================
@export_group("Currency")
@export var gold_coins: int = 0
@export var donate_coins: int = 0
