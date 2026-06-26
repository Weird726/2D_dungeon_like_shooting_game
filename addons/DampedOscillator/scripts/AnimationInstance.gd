extends Node

## 目标节点引用（弱引用检测是否已被释放）
var node: Node
## 目标属性名（字符串形式，如 "position:y"）
var property: String
## 属性的初始值（动画结束时恢复到此值）
var original_value: Variant

## 弹簧力系数（控制振荡频率）
var spring_force: float = 0.0
## 阻尼系数（控制衰减速度）
var damp: float = 0.0
## 当前速度（每帧根据力学公式更新）
var velocity: float = 0.0
## 当前位移（偏离原始值的距离）
var displacement: float = 0.0
## 缩放系数（放大/缩小振荡幅度）
var scale_factor: float = 1.0
## 是否处于激活状态（队列模式下暂停时为 false）
var active: bool = true

## 动画开始时触发
signal started
## 动画结束时触发
signal ended

## 每帧物理处理：计算弹簧阻尼力学并应用到目标属性
##
## [b]难点说明[/b]：力学公式 F = -k*x - d*v（胡克定律 + 阻尼力），
## 其中 k 为弹簧力、d 为阻尼、x 为位移、v 为速度。
## 使用 weakref 检测目标节点是否已被释放，防止访问已销毁对象。
func _physics_process(delta: float) -> void:
	# 弹簧阻尼力学计算
	var force: float = -spring_force * displacement - damp * velocity
	velocity += force * delta
	displacement += velocity * delta

	# 弱引用检测：目标节点可能已被 queue_free()
	var wr: WeakRef = weakref(node)
	if not wr.get_ref():
		set_physics_process(false)
		queue_free()
		return

	# 根据属性类型应用不同的计算方式
	match typeof(node.get(property)):
		TYPE_FLOAT:
			node.set(property, original_value + displacement * scale_factor)
		TYPE_INT:
			node.set(property, original_value + int(displacement * scale_factor))
		TYPE_VECTOR2:
			node.set(property, original_value + Vector2(displacement, -displacement) * scale_factor)

	# 速度趋近于零时结束动画（阈值 0.001）
	if abs(velocity) < 0.001:
		end()

## 启动动画（队列模式下由前一个动画的 ended 信号触发）
func start() -> void:
	set_physics_process(true)
	active = true
	started.emit()

## 结束动画：恢复属性原始值并移除自身
func end() -> void:
	ended.emit()
	node.set(property, original_value)
	queue_free()