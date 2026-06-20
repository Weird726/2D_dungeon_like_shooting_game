extends TextureButton
class_name PlayerCard

## 卡片中显示的角色头像图标
@onready var icon: TextureRect = $Icon

## 当前卡片绑定的角色数据引用
var data: PlayerData

## 从 PlayerData 资源加载数据并更新卡片显示
func set_data(value: PlayerData) -> void:
	data = value
	icon.texture = data.icon
