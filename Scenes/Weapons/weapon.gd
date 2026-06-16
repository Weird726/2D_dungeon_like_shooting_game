extends Node2D
class_name Weapon

## 武器配置数据资源（伤害、冷却、子弹等参数）
@export var data: WeaponData
## 武器旋转轴心节点，武器围绕此节点旋转朝向鼠标
@onready var pivot: Node2D = $Pivot

## 武器使用接口，子类（如 WeaponRange）重写实现具体攻击逻辑
func use_weapon() -> void:
	pass
