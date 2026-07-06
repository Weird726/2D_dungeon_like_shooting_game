extends Node2D
class_name WeaponController

## 当前装备的武器（支持运行时切换）
var current_weapon: Weapon
## 瞄准目标位置（玩家模式 = 鼠标位置，AI 模式 = 玩家位置）
##
## [b]难点说明[/b]：WeaponRange 通过 get_parent() 读取此变量
## WeaponController 仅负责存储 target_pos，不再直接控制 pivot 旋转
## 旋转和翻转由 WeaponRange._process() 自主管理
var target_pos: Vector2

## 从全局单例获取武器场景并实例化，装备到当前角色上
##
## [b]难点说明[/b]：武器实例化后需手动调整 Y 坐标（-8）对齐角色握持位置，
## 因为武器的 pivot 和角色的视觉中心不在同一坐标系原点。
## 此偏移值需在编辑器中反复调试确定。
##
## [b]难点说明[/b]：AI/玩家双模式装备
## is_ai 参数控制武器旋转目标来源：
## - false（默认）：玩家控制，WeaponRange 使用 get_global_mouse_position()
## - true：AI 控制，WeaponRange 读取 WeaponController.target_pos
## 由 enemy.gd 在 _ready() 中传入 is_ai = true
func equip_weapon(data: WeaponData, is_ai: bool = false) -> void:
	var weapon_scene = Global.all_weapons[data.weapon_name]
	var weapon: Weapon = weapon_scene.instantiate()
	weapon.global_position.y = -8
	current_weapon = weapon
	current_weapon.data = data
	# AI 模式下设置 WeaponRange 的控制标志
	if is_ai and current_weapon is WeaponRange:
		(current_weapon as WeaponRange).is_ai_controlled = true
	add_child(weapon)
