class_name DamageSystem
extends RefCounted

# Цей скрипт - "Бухгалтерія війни".
# Він рахує, скільки шкоди пройде крізь броню.

# Формула захисту (схожа на Warcraft 3 / Dota / LoL)
# 50 броні = зменшення шкоди десь на 23%
const ARMOR_COEFFICIENT: float = 0.06 

static func apply_defense(data: DamageData, defender_stats: StatsComponent) -> int:
	var final_damage = data.amount
	
	# 1. Якщо це фізична атака -> враховуємо Броню (Armor)
	if data.damage_type == GameEnums.DamageType.PHYSICAL:
		if defender_stats:
			var armor = defender_stats.get_stat("armor")
			
			# Формула зменшення шкоди
			# Якщо броня 0 -> множник 1.0 (повна шкода)
			# Якщо броня велика -> множник менший (шкода зменшується)
			var reduction_multiplier = 1.0 - ( (armor * ARMOR_COEFFICIENT) / (1.0 + armor * ARMOR_COEFFICIENT) )
			
			final_damage *= reduction_multiplier
			
			# (Для налагодження)
			if armor > 0:
				print("Броня ", armor, " зменшила шкоду з ", data.amount, " до ", int(final_damage))
	
	# 2. Тут можна додати магічні резисти (Fire Resist і т.д.)
	# if data.damage_type == GameEnums.DamageType.FIRE:
	#    ...
	
	# Шкода не може бути меншою за 1 (щоб було видно, що вдарив)
	return max(1, int(final_damage))
