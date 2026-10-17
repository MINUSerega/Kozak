class_name GameEnums
extends Node

# Це перелік типів шкоди. 
# Комп'ютер бачить їх як цифри (0, 1, 2...), а ми — як слова.
enum DamageType { 
	PHYSICAL, 
	FIRE, 
	COLD, 
	LIGHTNING, 
	POISON, 
	CHAOS 
}

# Це перелік характеристик.
enum Stat { 
	STRENGTH, 
	DEXTERITY, 
	INTELLIGENCE, 
	VITALITY, 
	ARMOR, 
	EVASION, 
	MOVEMENT_SPEED 
}
