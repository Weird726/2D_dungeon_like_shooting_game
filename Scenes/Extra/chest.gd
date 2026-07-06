## 宝箱道具，玩家触碰后切换为开启状态并掉落金币
##
## [b]模块关系[/b]：
## room.create_props() → 随机放置 Chest 到房间内地砖上
## Chest._on_area_2d_body_entered() → 切换视觉（ChestClose→ChestOpen）
## → 实例化 Coin 并添加到场景树根节点（call_deferred 延迟挂载）
## Coin._on_body_entered() → Global.coins += 1 → EventBus.on_coin_picked
##
## [b]已知缺陷[/b]：Area2D 未配置碰撞掩码，且回调缺少 `body is Player` 类型守卫
## 房间内任何 PhysicsBody2D（敌人、道具等）进入检测范围都会触发开启
## 需在 _on_area_2d_body_entered 开头添加 `if not body is Player: return`
extends StaticBody2D
class_name Chest

## 金币预制场景，开启后实例化多个掉落
const COIN_SCENE = preload("uid://dt8r7fckknna4")


## 每次开启掉落的金币数量（可在编辑器 Inspector 中调整）
@export var coin_amount := 5

## 宝箱关闭状态的精灵（开启后隐藏）
@onready var chest_close: Sprite2D = $ChestClose
## 宝箱开启状态的精灵（初始 visible=false，开启后显示）
@onready var chest_open: Sprite2D = $ChestOpen
## 开启音效播放器
@onready var chest_sound: AudioStreamPlayer = $ChestSound
## 金币掉落位置标记（y 偏移 18，使金币出现在宝箱下方）
@onready var drop_position: Marker2D = $DropPosition

## 是否已开启，防止重复触发
var collected: bool


## 玩家进入检测区域回调：切换视觉 → 播放音效 → 掉落金币 → 标记已收集
##
## [b]难点说明[/b]：call_deferred 延迟挂载的时序问题
## `get_tree().root.call_deferred("add_child", coin)` 将金币添加到场景树根节点
## 但下一行 `coin.global_position = ...` 在 coin 尚未进入场景树时执行
## 此时 coin 无父节点，global_position 计算结果可能不准确
## 正确做法：先设置 position（本地坐标），再 call_deferred 添加；
## 或在 deferred 回调中设置 global_position
##
## [b]难点说明[/b]：缺少类型守卫（已知缺陷）
## 当前未检查 body 是否为 Player，任何物理体进入都会触发
## 应添加 `if not body is Player: return` 作为第一行守卫
func _on_area_2d_body_entered(body: Node2D) -> void:
	# 已收集则直接返回（防止重复触发）
	if collected: return
	
	# 切换视觉：隐藏关闭状态，显示开启状态
	chest_close.hide()
	chest_open.show()
	# 播放开启音效
	chest_sound.play()
	
	# 批量生成金币并散落在掉落点附近（x 方向 ±30 像素随机偏移）
	for i in coin_amount:
		var coin = COIN_SCENE.instantiate() as Coin
		get_tree().root.call_deferred("add_child", coin)
		var pos = drop_position.global_position
		coin.global_position = Vector2(randf_range(pos.x - 30, pos.x + 30), pos.y)
	
	# 标记为已收集，后续触发直接 return
	collected = true
