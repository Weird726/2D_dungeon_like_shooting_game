extends TextureButton
class_name WeaponCard  

## 卡片中显示的武器图标
@onready var icon: TextureRect = $Icon
## 触碰音效播放器（鼠标悬停时触发）
@onready var hover_sound: AudioStreamPlayer = $HoverSound
## 选择指示框（选中时显示，用于单选视觉反馈）
@onready var selector: TextureRect = $Selector
## 描述面板（悬停时显示武器详细属性）
@onready var description_panel: DescriptionPanel = $DescriptionPanel

## 当前卡片绑定的武器数据引用
var data: WeaponData

## 从 WeaponData 资源加载数据并更新卡片显示
func set_data(value: WeaponData) -> void:
	data = value
	icon.texture = data.icon
	set_description()

## 格式化武器属性文本并写入描述面板
func set_description() -> void:
	var string := "Weapon: %s" % data.weapon_name
	string += "Damage: %.0f\nCooldown: %.0f\nMana Cost: %.0f\nSpread: %.0f\nBullet Spread: %.0f\nDescription: %s" % [data.damage, data.cooldown, data.mana_cost, data.spread, data.bullet_spreed, data.description]
	description_panel.set_text(string)

## 鼠标悬停回调：播放音效并对图标和描述面板施加阻尼振荡动画
##
## [b]难点说明[/b]：同时对 icon 和 description_panel 施加两组 DampedOscillator 动画：
## ① scale 缩放弹跳（与图标同步）
## ② rotation_degrees 旋转摆动（仅描述面板，角度随机 -10°~10°）
## 旋转的 scale_factor 使用 0.5 * randf_range(-20, 20)，使每次摆动方向和幅度不同。
func _on_mouse_entered() -> void:
	hover_sound.play()
	DampedOscillator.animate(icon, "scale", randf_range(400, 450), randf_range(5, 10), randf_range(10, 15), 0.5)
	
	description_panel.show()
	DampedOscillator.animate(description_panel, "scale", randf_range(400, 450), randf_range(5, 10), randf_range(10, 15), 0.5)
	DampedOscillator.animate(description_panel, "rotation_degrees", 300, 7.5, 15, 0.5 * randf_range(-20, 20))

## 鼠标离开回调：隐藏描述面板
func _on_mouse_exited() -> void:
	description_panel.hide()
