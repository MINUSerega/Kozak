extends CanvasLayer

# --- ГОЛОВНІ ПАПКИ ---
@onready var gameplay_hud = $GameplayHUD
@onready var death_screen = $DeathScreen
@onready var windows = $Windows 
@onready var system_menu = $SystemMenu

# --- ШЛЯХИ ---
@onready var health_bar = $GameplayHUD/HUDHealthBar
@onready var btn_respawn = $DeathScreen/RespawnButton
@onready var btn_inventory_open = $GameplayHUD/BtnInventoryOpen 

# ШЛЯХ ДО СІТКИ ІНВЕНТАРЮ (Перевір, чи правильний шлях у тебе в сцені!)
# Windows -> InventoryBackground -> GridContainer
@onready var inventory_grid = $Windows/InventoryBackground/GridContainer

# Шляхи до меню паузи
@onready var pause_menu = $SystemMenu/PauseMenu
@onready var btn_resume = $SystemMenu/PauseMenu/VBoxContainer/BtnResume
@onready var btn_quit = $SystemMenu/PauseMenu/VBoxContainer/BtnQuit

var player_node: Node2D
var game_paused: bool = false

func _ready():
	# 1. ХОВАЄМО ЗАЙВЕ
	gameplay_hud.show()
	death_screen.hide()
	windows.hide()
	system_menu.hide()
	
	# 2. ПІДКЛЮЧАЄМО КНОПКИ
	if btn_respawn: btn_respawn.pressed.connect(_on_respawn_pressed)
	if btn_resume: btn_resume.pressed.connect(toggle_pause)
	if btn_quit: btn_quit.pressed.connect(_on_quit_pressed)
	if btn_inventory_open: btn_inventory_open.pressed.connect(toggle_inventory)
		
	# 3. ШУКАЄМО ГРАВЦЯ І ПІДКЛЮЧАЄМО СИГНАЛИ
	await get_tree().process_frame
	player_node = get_tree().get_first_node_in_group("Player")
	
	if player_node:
		player_node.health_changed.connect(_on_health_changed)
		player_node.player_died.connect(_on_player_died)
		
		# [НОВЕ] Слухаємо, коли оновиться інвентар
		if player_node.has_signal("inventory_updated"):
			player_node.inventory_updated.connect(update_inventory_visuals)
		
		if player_node.stats and player_node.health:
			health_bar.max_value = player_node.stats.get_stat("max_health")
			health_bar.value = player_node.health.current_health

# --- ФУНКЦІЯ МАЛЮВАННЯ ПРЕДМЕТІВ [НОВЕ] ---
func update_inventory_visuals():
	var slots = inventory_grid.get_children()
	var items = player_node.inventory
	
	for i in range(slots.size()):
		var slot = slots[i]
		
		# Знаходимо Іконку і Текст
		var icon_node = slot.get_node_or_null("Icon")
		var amount_label = slot.get_node_or_null("AmountLabel") # [НОВЕ]
		
		if not icon_node: icon_node = slot # Резерв, якщо немає окремої іконки
		
		if i < items.size():
			var item = items[i]
			icon_node.texture = item.icon
			slot.tooltip_text = item.name
			
			# [НОВЕ] Логіка для цифр
			if amount_label:
				# Показуємо цифру тільки якщо предмета більше ніж 1
				if item.quantity > 1:
					amount_label.text = str(item.quantity)
					amount_label.show()
				else:
					amount_label.hide() # Для меча цифра не потрібна
		else:
			icon_node.texture = null
			slot.tooltip_text = ""
			if amount_label: amount_label.hide()

# --- ОБРОБКА ВВОДУ ---
func _input(event):
	if not player_node or (player_node.has_method("is_dead") and player_node.is_dead): return

	if event.is_action_pressed("ui_cancel"): 
		if windows.visible:
			toggle_inventory()
		else:
			toggle_pause()

	if event.is_action_pressed("inventory"):
		if not game_paused:
			toggle_inventory()

func toggle_inventory():
	windows.visible = not windows.visible
	# Оновлюємо картинки щоразу при відкритті, про всяк випадок
	if windows.visible:
		update_inventory_visuals()

func toggle_pause():
	game_paused = not game_paused
	get_tree().paused = game_paused
	if game_paused: system_menu.show()
	else: system_menu.hide()

# --- РЕАКЦІЇ НА ГРАВЦЯ ---
func _on_health_changed(new_health: float):
	if health_bar: health_bar.value = new_health

func _on_player_died():
	windows.hide() 
	system_menu.hide()
	death_screen.show()

# --- КНОПКИ ---
func _on_respawn_pressed():
	death_screen.hide()
	if player_node and player_node.has_method("respawn"):
		player_node.respawn()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
