extends Weapon
class_name WeaponRange

## 武器精灵，用于显示武器外观和翻转朝向
@onready var sprite: Sprite2D = %Sprite2D
## 枪口位置标记，子弹从此处生成并发射
@onready var fire_pos: Marker2D = %FirePos

## 武器朝向方向向量（从武器指向目标位置）
var direction: Vector2
## 射击冷却计时器（秒），归零时允许再次射击
var cooldown: float

## 是否为 AI 控制（true = 读取父节点 WeaponController.target_pos，false = 使用鼠标位置）
##
## [b]难点说明[/b]：AI/玩家双模式设计
## 玩家控制时 is_ai_controlled = false，_process 使用 get_global_mouse_position()
## AI 控制时 is_ai_controlled = true，_process 读取父节点 WeaponController.target_pos
## （由 Enemy.mange_weapon 每帧设为玩家位置）
## 否则敌人武器会始终瞄准鼠标而非玩家，导致射击方向错误
var is_ai_controlled: bool = false

## 每帧自主管理武器旋转 + 翻转（WeaponController 仅负责提供 target_pos）
##
## [b]难点说明[/b]：旋转与翻转一体化
## pivot.look_at() 控制武器朝向（旋转轴心在握把位置）
## sprite.flip_v 控制精灵上下翻转（当目标在左侧时）
## 两者必须在同一帧内同步完成，否则枪口位置与精灵朝向不一致
##
## [b]难点说明[/b]：目标位置来源分离
## 玩家模式：get_global_mouse_position()（实时鼠标位置）
## AI 模式：父节点 WeaponController.target_pos（由 Enemy 每帧设为玩家位置）
## WeaponController 不再直接调用 pivot.look_at()，旋转完全由 WeaponRange 自管理
func _process(delta: float) -> void:
	if is_ai_controlled:
		# AI 模式：从父节点 WeaponController 读取目标位置（由 Enemy 每帧更新为玩家位置）
		direction = (get_parent() as WeaponController).target_pos - global_position
	else:
		# 玩家模式：直接使用鼠标位置
		direction = get_global_mouse_position() - global_position
	# 旋转 pivot 朝向目标（pivot 在 Weapon 基类中定义，位于握把位置）
	pivot.look_at(direction + global_position)
	# 翻转精灵（目标在左侧时 flip_v = true）
	sprite.flip_v = direction.x < 0

## 远程武器攻击逻辑：生成子弹 → 设置位置/旋转 → 添加到场景树
func use_weapon() -> void:
	var bullet: Bullet = data.bullet_scene.instantiate()
	bullet.setup(data)
	# 获取子弹全局位置（枪口标记处）
	bullet.global_position = fire_pos.global_position
	# 获取旋转角度+旋转弧度添加随机性（范围散射值)
	bullet.global_rotation = pivot.global_rotation + deg_to_rad(randf_range(-data.spread, data.spread))
	# 添加到场景树根节点，使子弹在全局坐标系中独立飞行
	get_tree().root.add_child(bullet)
