extends Area2D
class_name Bullet

## 武器的引用
var data: WeaponData


## 子弹武器的设置类
func setup(data: WeaponData) -> void:
	self.data = data


## 用于移动子弹
func _process(delta: float) -> void:
	# 判断子弹数据是否被引用（防御性编程)
	if not data: return
	move_local_x(data.bullet_speed * delta)


## 碰撞体（如敌人、墙壁等）时销毁子弹
func _on_body_entered(body: Node2D) -> void:
	queue_free()
