extends Resource
class_name PlayerData

## 角色选择界面显示的头像图标
@export var icon: Texture2D
## 角色唯一标识符（用于存档、解锁判断等）
@export var id: String
## 最大生命值（初始生命值）
@export var max_hp: float = 5.0
## 移动速度（像素/秒）
@export var move_speed: int = 200
## 魔法值（用于技能消耗）
@export var magic: float = 1.0
