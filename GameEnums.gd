class_name GameEnums
extends Node

## Перелік типів шкоди у грі
enum DamageType {
	PHYSICAL,
	FIRE,
	COLD,
	LIGHTNING,
	POISON,
	CHAOS,
	COSMIC
}

## Перелік основних характеристик персонажа та монстрів
enum Stat {
	STRENGTH,
	DEXTERITY,
	INTELLIGENCE,
	VITALITY,
	ARMOR,
	EVASION,
	MOVEMENT_SPEED
}

## Слоти екіпірування персонажа
enum EquipmentSlot {
	WEAPON,
	OFFHAND,
	HEAD,
	CHEST,
	LEGS,
	FEET,
	ACCESSORY
}