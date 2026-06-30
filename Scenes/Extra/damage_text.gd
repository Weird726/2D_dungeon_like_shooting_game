extends Control
class_name DamageText

## 伤害数值标签，显示本次伤害的具体数值
@onready var label: Label = $Label

## 设置伤害数值并在 0.5 秒后自动销毁节点
func setup(value: float) -> void:
	label.text = str(value)
	# 使用 await + create_timer 实现延时销毁，比 Timer 节点更轻量
	await get_tree().create_timer(0.5).timeout
	queue_free()
