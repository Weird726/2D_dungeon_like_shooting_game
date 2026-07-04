## 可交互道具（如箱子、桶等），玩家触碰时触发阻尼振荡动画
extends Area2D
class_name Prop

## 道具精灵，用于显示外观和施加缩放/旋转动画
@onready var sprite: Sprite2D = $Sprite2D


## 玩家碰撞触发回调：对道具精灵施加阻尼振荡效果
##
## [b]难点说明[/b]：DampedOscillator.animate() 参数含义
## ① target: 动画目标节点（sprite）
## ② property: 动画属性名（"scale"）
## ③ amplitude: 振幅（250，控制振荡幅度）
## ④ frequency: 频率（10，控制振荡快慢）
## ⑤ damping: 阻尼系数（17，控制衰减速度）
## ⑥ phase: 初始相位（0.5 * randf_range(0, 1)，随机偏移使每次触碰效果不同）
func _on_body_entered(body: Node2D) -> void:
	DampedOscillator.animate(sprite, "scale", 250, 10, 17, 0.5 * randi_range(0, 1))
