extends Node2D
class_name WeaponController

## 测试用手枪武器引用（后续改为动态切换）
@onready var weapon_pistol: WeaponRange = $WeaponRangePistol

## 当前装备的武器（支持运行时切换）
var current_weapon: Weapon
## 鼠标在世界坐标中的位置，用于武器朝向计算
var target_pos: Vector2

## 初始化当前武器为手枪
func _ready() -> void:
	current_weapon = weapon_pistol

## 每帧追踪鼠标位置并旋转武器朝向
func _process(delta: float) -> void:
	target_pos = get_global_mouse_position()
	rotate_weapon()

## 控制当前武器旋转朝向鼠标
##
## [b]难点说明[/b]：通过 pivot 节点的 look_at() 实现旋转，
## 而非直接旋转武器根节点，因为武器的旋转轴心（pivot）
## 通常在握把位置，而非精灵图像中心。
func rotate_weapon() -> void:
	if not current_weapon:
		return
	
	current_weapon.pivot.look_at(target_pos)
