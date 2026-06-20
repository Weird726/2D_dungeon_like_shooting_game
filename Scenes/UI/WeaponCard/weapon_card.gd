extends TextureButton
class_name WeaponCard  

## 卡片中显示的武器图标
@onready var icon: TextureRect = $Icon

## 当前卡片绑定的武器数据引用
var data: WeaponData

## 从 WeaponData 资源加载数据并更新卡片显示
func set_data(value: WeaponData) -> void:
	data = value
	icon.texture = data.icon
