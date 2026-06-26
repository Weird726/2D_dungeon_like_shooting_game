extends Node

## 用户存档文件路径
var save_path: String = "user://save.json"

## 全局设置，存储音量、音效和全屏等用户偏好
var settings: Dictionary = {
	"music": true,
	"sfx": true,
	"fullscreen": true
}

## 全部可选角色场景映射（key 为角色 id，value 为 PackedScene）
var all_players: Dictionary[String, PackedScene] = {
	"Bunny": preload("uid://bmkt5wibg2k55"),
	"Dog": preload("uid://pd4h72eqbo16"),
	"Mouse": preload("uid://dnsjdwshtpqp2"),
	"Cat": preload("uid://bajjniw8jfhwc"),
}

## 全部可选武器场景映射（key 为武器名称，value 为 PackedScene）
var all_weapons: Dictionary[String, PackedScene] = {
	"Ak47": preload("uid://cxdab8nut0a6g"),
	"Mp7": preload("uid://bartsw5ocoyll"),
	"Pistol": preload("uid://jo8ht7pc50mw"),
	"R93": preload("uid://cadvltt3u0qu8"),
	"Spas12": preload("uid://d3pjsry6r4xtr"),
	"Thomson": preload("uid://cseoobyejbqvh"),
	"Uzi": preload("uid://n28dex5w8mxf"),
}

## 当前选中的角色数据（由角色选择界面赋值，未选择时为 null）
var selected_player: PlayerData
## 当前选中的武器数据（由角色选择界面赋值，未选择时为 null）
var selected_weapon: WeaponData

## 根据选中角色 id 从 all_players 中取出对应的 PackedScene
##
## [b]难点说明[/b]：selected_player 可能为 null（如 F6 单独运行 Arena 场景、
## 或用户未选择角色就进入战斗），访问 null.id 会崩溃。
## 调用前需确保 selected_player 已被赋值，或在此处加空值保护。
func get_player() -> PackedScene:
	return all_players[selected_player.id]

## 根据选中武器名称从 all_weapons 中取出对应的 PackedScene
##
## [b]难点说明[/b]：与 get_player() 同理，selected_weapon 可能为 null，
## 访问 null.weapon_name 会崩溃。调用前需确保已赋值或加空值保护。
func get_weapon() -> PackedScene:
	return all_weapons[selected_weapon.weapon_name]

## 将当前设置持久化到磁盘
func save_data() -> void:
	var save: Dictionary = settings.duplicate()
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	var json_string: String = JSON.stringify(save)
	file.store_string(json_string)
	file.close()

## 从磁盘加载存档，若文件不存在则使用默认值
func load_data() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	var json: String = file.get_as_text()
	var data: Dictionary = JSON.parse_string(json)
	# 仅覆盖已存在的键，防止存档字段与代码不同步
	for key in data:
		if settings.has(key):
			settings[key] = data[key]
	file.close()
