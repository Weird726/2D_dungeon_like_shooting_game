extends Node2D
class_name Arena

## 代替原有光标的新精灵图
@export var arena_cursor: Texture2D

## 生命值进度条，显示当前/最大生命值的比例
@onready var health_bar: TextureProgressBar = %HealthBar
## 魔法值进度条，显示当前/最大魔法值的比例
@onready var mana_bar: TextureProgressBar = %ManaBar

## 监听全局事件总线，当玩家生命值变化时更新 HUD
func _ready() -> void:
	# 进入场景时切换全局光标为当前场景专用光标
	Cursor.sprite.texture = arena_cursor
	EventBus.on_player_health_updated.connect(_on_player_health_updated)
	load_game_selection()

## 从全局单例读取选中的角色场景并实例化，然后装备选中的武器
func load_game_selection() -> void:
	var player: Player = Global.get_player().instantiate()
	add_child(player)
	# 角色实例化后再装备武器，因为武器控制器是角色的子节点
	player.weapon_controller.equip_weapon()


## 生命值变化回调，更新进度条显示
##
## [b]难点说明[/b]：TextureProgressBar.value 范围是 0~1（比例），
## 而非 0~100（百分比），因此直接用 current/max 计算比例。
## 若进度条配置为 0~100，则需乘以 100。
func _on_player_health_updated(current: float, max: float) -> void:
	health_bar.value = current / max