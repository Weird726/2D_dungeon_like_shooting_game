extends Control
class_name DescriptionPanel

## 描述文本标签（通过 NinePatchRect 背景实现自适应尺寸）
@onready var label: Label = $NinePatchRect/Label

## 设置描述面板的显示文本
func set_text(value: String) -> void:
	label.text = value
