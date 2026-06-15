extends Resource
class_name WeaponData

## 武器显示名称（用于 UI 展示）
@export var weapon_name: String
## 武器图标纹理（用于背包/选择界面显示）
@export var icon: Texture2D
## 武器实例化场景（武器在游戏中的实体表现）
@export var scene: PackedScene
## 单次攻击伤害值（浮点数，支持小数伤害）
@export var damage: float
## 攻击冷却时间（秒），控制两次攻击的最小间隔
@export var cooldown: float
## 魔法消耗（每次攻击扣除的魔法值）
@export var mana_cost: float
## 射击扩散角度（弧度），影响子弹发射方向的随机偏移范围
@export var spread: float
## 子弹扩散系数（弧度），子弹实际飞行方向相对于瞄准方向的偏移
@export var bullet_spreed: float
## 子弹预制场景（每次射击生成的子弹实体）
@export var bullet_scene: PackedScene
## 武器描述文本（用于 UI 中的武器详情面板）
@export var description: String
