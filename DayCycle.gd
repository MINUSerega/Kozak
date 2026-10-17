extends Node2D

# Швидкість обертання (градуси за секунду)
# 10.0 = повільний день
# 50.0 = дуже швидкий день
@export var rotation_speed = 10.0

func _process(delta):
	# Ми просто додаємо кут повороту кожну секунду
	rotation_degrees += rotation_speed * delta
