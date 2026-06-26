extends Node

## 动画实例预制场景
var animation_instance: PackedScene = preload("res://addons/DampedOscillator/scripts/animation_instance.tscn")
## 队列系统开关（启用后同一属性的多次动画会排队而非覆盖）
var queue_system_enabled: bool = false

## 对目标节点的指定属性施加阻尼振荡动画
##
## [param node] 目标节点（如 self、$Sprite 等）
## [param property] 要动画化的属性名（如 "position:y"、"scale:x"）
## [param spring_force] 弹簧力（越大振荡频率越高）
## [param damp] 阻尼系数（越大越快停下来）
## [param velocity] 初始速度（决定初始冲击力大小）
## [param scale_factor] 缩放系数（放大/缩小振荡幅度）
##
## [b]难点说明[/b]：property 使用字符串而非直接引用，
## 因此支持任意属性（float/int/Vector2），但拼写错误不会报错，
## 需确保属性名与节点实际属性完全匹配。
func animate(node: Node, property: String, spring_force: float, damp: float, velocity: float, scale_factor: float) -> void:
	# 创建新的动画实例
	var i: Node = animation_instance.instantiate()

	# 设置目标节点和属性
	i.node = node
	i.property = property
	i.original_value = node.get(property)

	# 设置振荡器参数
	i.spring_force = spring_force
	i.damp = damp
	i.velocity = velocity
	i.scale_factor = scale_factor

	# 队列系统：检查是否已有同一属性的动画在运行
	for animation: Node in get_children():
		if animation.node == node and animation.property == property:
			if not queue_system_enabled:
				# 非队列模式：继承当前值并终止旧动画
				i.original_value = animation.original_value
				animation.end()
			else:
				# 队列模式：等新动画结束后再启动当前动画
				i.active = false
				animation.ended.connect(Callable(i, "start"))
				i.original_value = animation.original_value
				i.set_physics_process(false)
			add_child(i)
			return

	# 无冲突，直接启动
	add_child(i)