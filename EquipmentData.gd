extends ItemData
class_name EquipmentData

# Куди це вдягається?
enum EquipmentSlot {
	WEAPON,   # Зброя (права рука)
	OFFHAND,  # Щит / Друга зброя (ліва рука)
	HEAD,     # Шолом
	CHEST,    # Броня / Тіло
	LEGS,     # Штани
	FEET,     # Чоботи
	ACCESSORY # Кільця / Амулети
}

@export var slot_type: EquipmentSlot = EquipmentSlot.WEAPON

# --- ЗБРОЯ (Заповнюємо тільки для мечів/посохів) ---
@export_group("Weapon Stats")
@export var damage: float = 0.0
@export var attack_range: float = 40.0
@export var attack_speed: float = 1.0
# Який стат збільшує шкоду? (strength / dexterity / intelligence)
@export_enum("strength", "dexterity", "intelligence", "none") var scaling_stat: String = "none"

# --- БРОНЯ (Заповнюємо для одягу) ---
@export_group("Defensive Stats")
@export var defense: float = 0.0      # Фізичний захист
@export var magic_resist: float = 0.0 # Магічний захист (на майбутнє)

# --- БОНУСИ ХАРАКТЕРИСТИК (Для кілець та магічної броні) ---
# Наприклад: Кільце дає +5 Сили.
@export_group("Stat Bonuses")
@export var bonus_strength: float = 0.0
@export var bonus_dexterity: float = 0.0
@export var bonus_intelligence: float = 0.0
@export var bonus_constitution: float = 0.0 # Це дасть +до Max HP
@export var bonus_speed: float = 0.0        # Чоботи можуть давати швидкість

# --- ВІЗУАЛ ---
# Сцена, яка прикріпиться до гравця (меч у руці або спрайт шолома)
@export_group("Visuals")
@export var equipment_scene: PackedScene 
# Або якщо ми просто міняємо текстуру спрайта:
@export var equipment_texture: Texture2D
