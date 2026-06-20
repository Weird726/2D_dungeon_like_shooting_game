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
		player_container.add_child(card)
		card.set_data(data)
	
	# 为每个 WeaponData 资源实例化一张武器卡片
	for data: WeaponData in weapons:
		var card: WeaponCard = WEAPON_CARD_SCENE.instantiate()
		weapon_container.add_child(card)
		card.set_data(data)
