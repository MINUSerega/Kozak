extends Resource
class_name ItemData

# --- 1. КАТЕГОРІЇ (Для фільтрів) ---
enum ItemType {
	WEAPON,     # Зброя
	ARMOR,      # Обладунки
	CONSUMABLE, # Банки, їжа (Хілки, МП)
	RESOURCE,   # Трави, руда, крафт
	QUEST,      # Квестові предмети
	MISC        # Різне (мотлох)
}

# --- 2. РІДКІСНІСТЬ (Для кольору рамки) ---
enum Rarity {
	COMMON,     # Сірий
	UNCOMMON,   # Зелений
	RARE,       # Синій
	EPIC,       # Фіолетовий
	LEGENDARY   # Помаранчевий
}

# --- НАЛАШТУВАННЯ ПРЕДМЕТА ---
@export_group("General")
@export var id: String = ""
@export var name: String = "Item"
@export var type: ItemType = ItemType.MISC       # Вибираємо зі списку!
@export var rarity: Rarity = Rarity.COMMON       # Вибираємо рідкісність
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Economy & Stacking")
@export var price: int = 10                      # Ціна продажу
@export var is_stackable: bool = false
@export var max_stack_size: int = 1              # Для трав став 99 або 9999
var quantity: int = 1

@export_group("Stats")
@export var stats_bonus: AttributeData           # Якщо це меч/броня
