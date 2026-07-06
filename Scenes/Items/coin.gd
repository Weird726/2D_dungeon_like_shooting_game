## 金币拾取道具，玩家触碰时增加全局金币计数并通知 UI 更新
##
## [b]模块关系[/b]：
## Coin._on_body_entered() → Global.coins += 1（数据层递增）
## → EventBus.on_coin_picked.emit()（通知 UI 层）
## → Arena._on_coin_picked() → 播放音效 + 更新 Label 显示
extends Area2D
class_name Coin


## 玩家碰撞触发回调：递增金币计数 → 发射信号 → 销毁自身
##
## [b]难点说明[/b]：数据更新与信号发射顺序
## 必须先 Global.coins += 1，再 emit 信号
## 否则 Arena 回调中读取到的 Global.coins 还是旧值，UI 显示少 1
func _on_body_entered(body: Node2D) -> void:
	# 递增全局金币计数（数据层更新）
	Global.coins += 1
	# 通知所有监听者（Arena 播放音效 + 更新 UI）
	EventBus.on_coin_picked.emit()
	# 销毁金币实体（防止重复拾取）
	queue_free()
