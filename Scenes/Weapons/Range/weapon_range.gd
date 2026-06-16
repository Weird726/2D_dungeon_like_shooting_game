extends Weapon
class_name WeaponRange

## 武器精灵，用于显示武器外观和翻转朝向
@onready var sprite: Sprite2D = %Sprite2D

## 武器朝向方向向量（从武器指向鼠标位置）
var direction: Vector2

## 每帧更新武器旋转朝向
func _process(delta: float) -> void:
	rotate_weapon()

## 远程武器攻击逻辑（待实现：生成子弹、消耗魔法、冷却判断）
func use_weapon() -> void:
	pass

## 根据鼠标位置旋转武器并翻转精灵
##
## [b]难点说明[/b]：使用 flip_v 而非 scale.y 翻转，
## 因为武器精灵的 pivot 已在编辑器中调整，
## scale 翻转会破坏 pivot 位置导致旋转偏移。
func rotate_weapon() -> void:
	direction = get_global_mouse_position() - global_position
	sprite.flip_v = direction.x < 0
