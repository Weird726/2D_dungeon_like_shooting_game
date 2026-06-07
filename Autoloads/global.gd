extends Node

## 用户存档文件路径
var save_path: String = "user://save.json"

## 全局设置，存储音量、音效和全屏等用户偏好
var settings: Dictionary = {
	"music": true,
	"sfx": true,
	"fullscreen": true
}

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
