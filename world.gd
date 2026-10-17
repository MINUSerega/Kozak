extends Node2D

@onready var player = $Player

func _ready():
	# Тепер world.gd не керує інтерфейсом!
	# Уся магія з ХП, кнопками та меню відбувається всередині нової сцени GameUI.
	pass
