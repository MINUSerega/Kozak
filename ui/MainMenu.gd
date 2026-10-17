extends Control

func _ready():
	# Підключаємо сигнали натискання кнопок
	$VBoxContainer/BtnPlay.pressed.connect(_on_play_pressed)
	$VBoxContainer/BtnSettings.pressed.connect(_on_settings_pressed)
	$VBoxContainer/BtnExit.pressed.connect(_on_exit_pressed)

func _on_play_pressed():
	# Завантажуємо сцену зі світом гри
	# ЗМІНИ ЦЕЙ ШЛЯХ на шлях до твоєї сцени World.tscn!
	get_tree().change_scene_to_file("res://World.tscn")

func _on_settings_pressed():
	print("Тут будуть налаштування...")
	# Потім тут відкриємо інше вікно

func _on_exit_pressed():
	# Закриваємо гру
	get_tree().quit()
