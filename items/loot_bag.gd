extends Area2D

# Сюди ми передамо список предметів, які випали (масив ресурсів ItemData)
var items_inside: Array[ItemData] = []
var player_in_range = null

@onready var label = $Label

func _ready():
	label.hide()
	# Підключаємо сигнали входу/виходу з зони
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Таймер: через 10 хвилин (600 сек) мішок зникне сам
	get_tree().create_timer(1200.0).timeout.connect(queue_free)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = body
		label.show() # Показуємо "E"

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		label.hide() # Ховаємо "E"

func _input(event):
	# Якщо натиснули "E" і гравець поруч
	if event.is_action_pressed("interact") and player_in_range:
		loot_items()

func loot_items():
	if items_inside.is_empty():
		queue_free()
		return
		
	print("Підібрано мішок!")
	
	# Перевіряємо, чи вміє гравець приймати предмети
	if player_in_range and player_in_range.has_method("add_item"):
		for item in items_inside:
			# Викликаємо нову функцію гравця!
			player_in_range.add_item(item)
			print(" + Отримано: ", item.name)
		
	# Знищуємо мішечок, бо ми все забрали
	queue_free()
