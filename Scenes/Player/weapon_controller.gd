extends Node2D
class_name WeaponController

## 当前装备的武器（支持运行时切换）
var current_weapon: Weapon
## 鼠标在世界坐标中的位置，用于武器朝向计算
var target_pos: Vector2

## 每帧追踪鼠标位置并旋转武器朝向
func _process(delta: float) -> void:
	target_pos = get_global_mouse_position()
	rotate_weapon()

## 从全局单例获取武器场景并实例化，装备到当前角色上
##
## [b]难点说明[/b]：武器实例化后需手动调整 Y 坐标（-8）对齐角色握持位置，
## 因为武器的 pivot 和角色的视觉中心不在同一坐标系原点。
## 此偏移值需在编辑器中反复调试确定。
func equip_weapon() -> void:
	var weapon: Weapon = Global.get_weapon().instantiate()
	weapon.global_position.y = -8
	current_weapon = weapon
	current_weapon.data = Global.selected_weapon
	add_child(weapon)

## 控制当前武器旋转朝向鼠标
##
## [b]难点说明[/b]：通过 pivot 节点的 look_at() 实现旋转，
## 而非直接旋转武器根节点，因为武器的旋转轴心（pivot）
## 通常在握把位置，而非精灵图像中心。
func rotate_weapon() -> void:
	if not current_weapon:
		return
	
	current_weapon.pivot.look_at(target_pos)
