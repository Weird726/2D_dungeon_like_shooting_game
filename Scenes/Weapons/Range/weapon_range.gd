extends Weapon
class_name WeaponRange

## 武器精灵，用于显示武器外观和翻转朝向
@onready var sprite: Sprite2D = %Sprite2D
## 枪口位置标记，子弹从此处生成并发射
@onready var fire_pos: Marker2D = %FirePos

## 武器朝向方向向量（从武器指向鼠标位置）
var direction: Vector2
## 射击冷却计时器（秒），归零时允许再次射击
var cooldown: float

## 每帧更新武器旋转朝向
func _process(delta: float) -> void:
	rotate_weapon()

## 远程武器攻击逻辑（待实现：生成子弹、消耗魔法、冷却判断）
func use_weapon() -> void:
	var bullet: Bullet = data.bullet_scene.instantiate()
	bullet.setup(data)
	# 获取子弹全局位置
	bullet.global_position = fire_pos.global_position
	# 获取旋转角度+旋转弧度添加随机性（范围散射值)
	bullet.global_rotation = pivot.global_rotation + deg_to_rad(randf_range(-data.spread, data.spread))
	# 添加到场景树根节点，使子弹在全局坐标系中独立飞行
	get_tree().root.add_child(bullet)


## 根据鼠标位置旋转武器并翻转精灵
##
## [b]难点说明[/b]：使用 flip_v 而非 scale.y 翻转，
## 因为武器精灵的 pivot 已在编辑器中调整，
## scale 翻转会破坏 pivot 位置导致旋转偏移。
func rotate_weapon() -> void:
	direction = get_global_mouse_position() - global_position
	sprite.flip_v = direction.x < 0
