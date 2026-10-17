class_name DamageData
extends RefCounted

# Це "конверт", у якому ми передаємо інформацію про удар.

var amount: float = 0.0                      # Скільки шкоди
var source: Node = null                      # Хто вдарив (Козак чи Ворог)
var damage_type: int = GameEnums.DamageType.PHYSICAL  # Тип шкоди (Фізична, Вогонь...)
var is_critical: bool = false                # Чи це критичний удар?

# Функція створення (конструктор)
# Дозволяє писати: DamageData.new(10, self)
func _init(_amount: float, _source: Node, _type: int = GameEnums.DamageType.PHYSICAL):
	amount = _amount
	source = _source
	damage_type = _type
