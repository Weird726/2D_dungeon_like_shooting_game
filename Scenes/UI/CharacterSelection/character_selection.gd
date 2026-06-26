extends Control
class_name CharacterSelection

## 角色卡片预制场景（通过 UID 引用，避免路径依赖）
const PLAYER_CARD_SCENE = preload("uid://chfobwlpdyj4p")
## 武器卡片预制场景（通过 UID 引用）
const WEAPON_CARD_SCENE = preload("uid://djdnyv7k0co2f")

## 选择界面专用光标纹理
@export var selection_cursor: Texture2D
## 可选角色数据列表（在编辑器中配置 PlayerData 资源）
@export var players: Array[PlayerData]
## 可选武器数据列表（在编辑器中配置 WeaponData 资源）
@export var weapons: Array[WeaponData]

## 角色卡片容器（水平排列）
@onready var player_container: HBoxContainer = $PlayerContainer
## 武器卡片容器（水平排列）
@onready var weapon_container: HBoxContainer = $WeaponContainer
## UI 点击音效播放器
@onready var ui_sound: AudioStreamPlayer = $UISound
## 触碰音效播放器（鼠标悬停时触发）
@onready var hover_sound: AudioStreamPlayer = $HoverSound

## 初始化：切换光标并加载所有可选卡片
func _ready() -> void:
	Cursor.sprite.texture = selection_cursor
	load_selection_items()

## 清空并重建所有角色/武器选择卡片
##
## [b]难点说明[/b]：先遍历删除旧子节点再重建，
## 而非直接 add_child 追加，防止场景重复进入时卡片叠加。
## queue_free() 在当前帧结束后才真正移除，
## 因此删除和创建不会冲突。
func load_selection_items() -> void:
	for node in player_container.get_children():
		node.queue_free()
	for node in weapon_container.get_children():
		node.queue_free() 
	
	# 为每个 PlayerData 资源实例化一张角色卡片
	for data: PlayerData in players:
		var card: PlayerCard = PLAYER_CARD_SCENE.instantiate()
		card.pressed.connect(_on_player_card_pressed.bind(data))
		player_container.add_child(card)
		card.set_data(data)
	
	# 为每个 WeaponData 资源实例化一张武器卡片
	for data: WeaponData in weapons:
		var card: WeaponCard = WEAPON_CARD_SCENE.instantiate()
		card.pressed.connect(_on_weapon_card_pressed.bind(data))
		weapon_container.add_child(card)
		card.set_data(data)


## 开始按钮回调：过渡到战斗场景
##
## [b]难点说明[/b]：此处添加了空值保护（防御性编程），
## 未选完角色/武器时按开始不会进入战斗场景，防止后续 null 引用崩溃。
func _on_play_button_pressed() -> void:
	if not Global.selected_player:
		return
	if not Global.selected_weapon:
		return
	ui_sound.play()
	Transition.transition_to("res://Scenes/Arena/arena.tscn")

## 返回按钮回调：过渡回主菜单
func _on_back_button_pressed() -> void:
	ui_sound.play()
	Transition.transition_to("res://Scenes/UI/main_menu.tscn")

## 角色卡片点击回调：将选中的角色数据存入全局单例
func _on_player_card_pressed(data: PlayerData) -> void:
	ui_sound.play()
	Global.selected_player = data

## 武器卡片点击回调：将选中的武器数据存入全局单例
func _on_weapon_card_pressed(data: WeaponData) -> void:
	ui_sound.play()
	Global.selected_weapon = data


## 开始按钮鼠标悬停回调：播放触碰音效
func _on_play_button_mouse_entered() -> void:
	hover_sound.play()


## 返回按钮鼠标悬停回调：播放触碰音效
func _on_back_button_mouse_entered() -> void:
	hover_sound.play()
