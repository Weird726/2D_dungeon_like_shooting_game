extends Node2D
class_name HealthComponent

## 单位受伤时触发，传递伤害值
signal on_unit_damaged(amount: float)
## 单位治疗时触发，传递治疗值
signal on_unit_healed(amount: float)
## 单位死亡时触发（无参数，用于监听死亡事件）
signal on_unit_dead

## 当前生命值
var current_health: float
## 最大生命值（用于限制治疗上限）
var max_health: float

## 初始化生命值，通常在 _ready() 中调用
func init_health(value: float) -> void:
	current_health = value
	max_health = value

## 承受伤害，生命值归零时自动触发死亡
func take_damage(value: float) -> void:
	if current_health > 0:
		current_health -= value
		on_unit_damaged.emit(value)
		# 使用 <= 而非 == 防止浮点精度问题导致死亡未触发
		if current_health <= 0:
			die()

## 死亡处理：锁定生命值为 0 并发出死亡信号
func die() -> void:
	current_health = 0.0
	on_unit_dead.emit()

## 治疗单位，生命值不超过上限
##
## [b]难点说明[/b]：使用 min() 而非 if 判断，
## 可防止溢出治疗时生命值超过 max_health。
## 例如：当前 8/10 血，治疗 5 点，min(10, 8+5) = 10。
func heal(value: float) -> void:
	if current_health >= max_health:
		return
	# min() 确保治疗后的值不会超过 max_health
	current_health = min(max_health, current_health + value)
	on_unit_healed.emit(value)
