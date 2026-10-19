extends Resource
class_name MonsterData

@export_category("Основна Інформація")
@export var id: String = ""
@export var monster_name: String = "Unknown Monster"
@export var level: int = 1
@export var is_aggressive: bool = false
@export var xp_reward: int = 10

@export_category("Характеристики")
## Посилання на базові атрибути моба
@export var base_attributes: AttributeData

@export_category("Таблиця Луту (Дроп)")
## Словник луту у форматі: { "item_id": { "chance": 0.5, "min": 1, "max": 3 } }
@export var drops: Dictionary = {}
