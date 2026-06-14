extends Node2D
class_name Arena

## 生命值进度条，显示当前/最大生命值的比例
@onready var health_bar: TextureProgressBar = %HealthBar
## 魔法值进度条，显示当前/最大魔法值的比例
@onready var mana_bar: TextureProgressBar = %ManaBar

## 监听全局事件总线，当玩家生命值变化时更新 HUD
func _ready() -> void:
	EventBus.on_player_health_updated.connect(_on_player_health_updated)

## 生命值变化回调，更新进度条显示
##
## [b]难点说明[/b]：TextureProgressBar.value 范围是 0~1（比例），
## 而非 0~100（百分比），因此直接用 current/max 计算比例。
## 若进度条配置为 0~100，则需乘以 100。
func _on_player_health_updated(current: float, max: float) -> void:
	health_bar.value = current / max
