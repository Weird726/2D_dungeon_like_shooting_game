## 敌人生成器，管理房间内敌人的生成、追踪和房间清理检测
##
## [b]模块关系[/b]：
## Arena 持有 EnemySpawner 引用，在进入未清理房间时调用 spawn_enemies()
## Enemy 死亡时发射 on_enemy_die → EnemySpawner 监听并计数
## 全灭后发射 on_room_cleared → Arena 监听后执行 unlock_room()
extends Node2D
class_name EnemySpawner

## 当前房间内所有存活的敌人实例列表，用于计数和清理判定
var enemies: Array[Enemy] = []
## 当前房间已击杀的敌人数量（每清一个房间重置为 0）
var enemies_killed: int

## 初始化：连接敌人死亡全局信号
func _ready() -> void:
	EventBus.on_enemy_die.connect(_on_enemy_die)

## 在指定房间内生成随机敌人
##
## [b]难点说明[/b]：生成流程与坐标转换
## 1. 防御性检查：enemy_scenes 为空时直接返回
## 2. await 延时 0.5 秒：等待房间完全加载后再放置敌人
## 3. 随机数量：min~max 范围内随机
## 4. 坐标转换：get_free_spawn_position() 返回房间本地坐标
##    需通过 to_global() 转换为世界坐标
func spawn_enemies(data: LevelData, room: LevelRoom) -> void:
	if data.enemy_scenes.is_empty():
		return
	
	# 延时 0.5 秒，等待房间场景完全加载（防止地砖坐标未就绪）
	await get_tree().create_timer(0.5).timeout
	
	# 在配置范围内随机生成敌人数量
	var amount = randi_range(data.min_enemies_per_room, data.max_enemies_per_room)
	for i in amount:
		# 从敌人场景池中随机抽取一个预制体
		var random_scene = data.enemy_scenes.pick_random()
		var enemy: Enemy = random_scene.instantiate()
		enemies.append(enemy)
		# 添加到 Arena 节点下（enemy_spawner 的父节点）
		get_parent().add_child(enemy)
		# 获取房间内随机地砖位置（本地坐标）→ 转换为世界坐标
		var spawn_local_pos = room.get_free_spawn_position()
		var spawn_global_pos = room.to_global(spawn_local_pos)
		enemy.global_position = spawn_global_pos

## 敌人死亡信号回调：累加击杀计数，全灭时通知房间解锁
##
## [b]难点说明[/b]：房间清理判定逻辑
## 每次敌人死亡时检查：击杀数 >= 存活敌人数
## 条件满足时发射 on_room_cleared 信号，Arena 监听后执行 unlock_room()
## 最后清空列表和计数器，为下一个房间做准备
func _on_enemy_die() -> void:
	enemies_killed += 1
	if enemies_killed >= enemies.size():
		EventBus.on_room_cleared.emit()
		enemies.clear()
		enemies_killed = 0
