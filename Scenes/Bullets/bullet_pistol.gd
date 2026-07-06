## 子弹基类，实现直线飞行、碰撞伤害和自动销毁
extends Area2D
class_name Bullet

## 武器数据引用（伤害、速度等参数，由 setup() 注入）
var data: WeaponData


## 子弹初始化：注入武器数据，必须在添加到场景树前调用
##
## [b]难点说明[/b]：data 不在 _ready() 中初始化，
## 因为子弹是运行时动态实例化的，需由发射者（WeaponRange）传入数据。
func setup(data: WeaponData) -> void:
	self.data = data


## 每帧沿本地 X 轴移动子弹（飞行方向由 global_rotation 决定）
##
## [b]难点说明[/b]：使用 move_local_x 而非修改 position.x，
## 因为 move_local_x 沿节点本地坐标系移动，
## 子弹旋转后本地 X 轴即为飞行方向。
func _process(delta: float) -> void:
	# 防御性编程：data 未注入时跳过（防止实例化后未调用 setup 的异常子弹）
	if not data: return
	move_local_x(data.bullet_speed * delta)


## 碰撞体（如敌人、墙壁等）时销毁子弹并触发伤害/特效
##
## [b]难点说明[/b]：使用 `is` 类型检查区分碰撞目标
## 只有碰撞到 Enemy 类型时才造成伤害和伤害数字
## 碰撞到墙壁等其他类型时只生成爆炸特效，不造成伤害
func _on_body_entered(body: Node2D) -> void:
	# 在碰撞点生成爆炸特效（无论碰撞到什么都会触发）
	Global.create_explosion(global_position)
	if body is Enemy or body is Player:
		# 在碰撞体位置生成伤害数字
		Global.create_damage_text(data.damage, body.global_position)
		# 直接调用敌人生命组件的受伤方法，触发扣血 + 闪白 + 血条更新
		body.health_component.take_damage(data.damage)
	
	queue_free()
