extends TextureButton
class_name PlayerCard

## 卡片中显示的角色头像图标
@onready var icon: TextureRect = $Icon
## 触碰音效播放器（鼠标悬停时触发）
@onready var hover_sound: AudioStreamPlayer = $HoverSound
## 选择指示框（选中时显示，用于单选视觉反馈）
@onready var selector: TextureRect = $Selector

## 当前卡片绑定的角色数据引用
var data: PlayerData

## 从 PlayerData 资源加载数据并更新卡片显示
func set_data(value: PlayerData) -> void:
	data = value
	icon.texture = data.icon


## 鼠标悬停回调：播放音效并对图标施加阻尼振荡缩放动画
##
## [b]难点说明[/b]：使用 DampedOscillator 对 "scale" 属性施加弹簧阻尼动画，
## 参数使用 randf_range() 随机化，使每次悬停效果略有不同。
## scale 参数（0.5）控制振荡幅度，spring_force 和 damp 随机化控制弹性效果。
func _on_mouse_entered() -> void:
	hover_sound.play()
	DampedOscillator.animate(icon, "scale", randf_range(400, 450), randf_range(5, 10), randf_range(10, 15), 0.5)