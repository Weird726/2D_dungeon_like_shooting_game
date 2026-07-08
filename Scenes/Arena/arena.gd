## 地牢竞技场控制器，负责地牢生成、房间管理、玩家放置和信号调度
##
## [b]模块关系[/b]：
## LevelData（配置驱动）→ Arena（生成管线）→ LevelRoom（房间实例）
## Arena 通过 EventBus 接收玩家/敌人事件，调度 lock/unlock/spawn 流程
extends Node2D
class_name Arena

## 进入场景时替换全局光标的纹理
@export var arena_cursor: Texture2D
## 关卡配置数据（房间数、尺寸、敌人/道具池等），在编辑器中通过 .tres 配置
@export var level_data: LevelData

## HUD 生命值进度条，通过 EventBus 监听玩家血量变化实时更新
@onready var health_bar: TextureProgressBar = %HealthBar
## HUD 魔法值进度条（预留，未来实现魔法消耗系统）
@onready var mana_bar: TextureProgressBar = %ManaBar
## 小地图控制器，玩家进入房间时揭示对应格子
@onready var map_controller: MapController = $UI/MapController
## 敌人生成器，管理房间内敌人的生成与清理检测
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
## 金币总数显示标签，由 _ready() 和 _on_coin_picked() 实时更新
@onready var total_coins: Label = %TotalConins
@onready var coin_sound: AudioStreamPlayer = $CoinSound

## 网格坐标 → 房间实例的映射字典，null 占位表示坐标已分配但房间未实例化
var grid: Dictionary[Vector2i, LevelRoom] = {}
## 起始房间坐标（固定为原点 Vector2i.ZERO）
var start_room_coord: Vector2i
## 终点房间坐标（距起点欧式距离最远的房间）
var end_room_coord: Vector2i
var store_room_coord: Vector2i

## 单元格尺寸 = 房间尺寸 + 走廊尺寸，用于网格坐标到像素位置的换算
var grid_cell_size: Vector2i

## 当前玩家实例引用，由 load_game_selection() 创建并赋值
var player: Player
## 玩家当前所在的房间引用，每次进入新房间时更新
var current_room: LevelRoom


## 场景初始化管线：切换光标 → 连接信号 → 计算尺寸 → 生成地牢 → 放置玩家
##
## [b]难点说明[/b]：管线顺序严格依赖
## 布局 → 特殊房间 → 房间实例 → 走廊 → 玩家
## 每步依赖前序产出（如玩家放置需要房间已存在于 grid 中）
func _ready() -> void:
	Cursor.sprite.texture = arena_cursor
	EventBus.on_player_health_updated.connect(_on_player_health_updated)
	EventBus.on_player_room_entered.connect(_on_player_room_entered)
	EventBus.on_room_cleared.connect(_on_room_cleared)
	EventBus.on_coin_picked.connect(_on_coin_picked)
	
	# 单元格尺寸 = 房间宽高 + 走廊宽高，使相邻房间之间留出走廊空间
	grid_cell_size = Vector2i(
		level_data.room_size.x + level_data.corridor_size.x,
		level_data.room_size.y + level_data.corridor_size.y,
	)
	
	generate_level_layout()
	select_special_rooms()
	create_rooms()
	create_corridors()
	load_game_selection()
	
	# 标记起始房间为已清理，防止玩家出生在检测区内时误触发锁门
	var first_room: LevelRoom = grid[Vector2i.ZERO]
	first_room.is_cleared = true


func _process(_delta: float) -> void:
	# 同步金币显示与 Global.coins 实际值（防止编辑器硬编码的假数据）
	total_coins.text = str(Global.coins)
	if is_instance_valid(Global.player_ref):
		mana_bar.value = Global.player_ref.current_mana / Global.player_ref.data.magic

## 测试用调试输入：Esc 键强制解锁当前房间
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		current_room.unlock_room()
		current_room.is_cleared = true

## 使用随机游走算法生成地牢房间坐标布局
##
## [b]难点说明[/b]：算法核心是随机游走 + 冲突重试
## 50% 概率从已有房间中随机选起点（避免线性链），否则从当前房间扩展
## 若目标位置已被占用，最多重试 10 次寻找空位
func generate_level_layout() -> void:
	grid.clear()
	
	print("Creating layout...")
	var current_coord := Vector2i.ZERO
	grid[current_coord] = null
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]
	
	# 循环直到房间数量达到配置要求
	while grid.size() < level_data.num_rooms:
		# 50% 概率随机选择已有房间作为扩展起点（避免线性链）
		if randf() > 0.5:
			current_coord = grid.keys().pick_random()
		
		var random_direction = directions.pick_random()
		var next_coord = current_coord + random_direction
		
		var attempts = 0
		# 冲突重试：目标位置已占用时重新选方向
		while grid.has(next_coord) and attempts < 10:
			random_direction = directions.pick_random()
			next_coord = current_coord + random_direction
			attempts += 1
		
		if not grid.has(next_coord):
			grid[next_coord] = null
	
	for key: Vector2i in grid.keys():
		print(key)

## 遍历坐标网格，实例化房间场景并放置到对应像素位置
##
## [b]难点说明[/b]：房间创建后立即生成道具
## create_props() 在 add_child 之后、connect_rooms 之前调用
## 确保道具放置在墙壁打通前完成，避免道具出现在门的位置
func create_rooms() -> void:
	print("Creating rooms...")
	for room_coord: Vector2i in grid.keys():
		var room_instance: LevelRoom = level_data.room_scene.instantiate()
		# 网格坐标 × 单元格尺寸 = 像素位置
		room_instance.position = room_coord * grid_cell_size
		add_child(room_instance)
		room_instance.create_props(level_data)
		
		# 替换 null 占位为实际房间实例
		grid[room_coord] = room_instance
		
		if room_coord == store_room_coord:
			room_instance.is_cleared = true
			room_instance.setup_room_as_shop(level_data)
		
		# 通过方向来连接房间
		connect_rooms(room_coord, room_instance)

## 在相邻房间之间生成走廊视觉连接
##
## [b]难点说明[/b]：走廊位置使用偏移计算
## 水平走廊：从房间右边缘偏移半个单元格宽度
## 垂直走廊：从房间下边缘偏移半个单元格高度
func create_corridors() -> void:
	print("Creating corridors...")
	for room_coord: Vector2i in grid.keys():
		var room_instance: LevelRoom = grid[room_coord]
		
		var right_neighbor = room_coord + Vector2i.RIGHT
		if grid.has(right_neighbor):
			var corridor: Node2D = level_data.h_corridor.instantiate()
			corridor.position = room_instance.position + Vector2(
				grid_cell_size.x / 2.0, 0)
			add_child(corridor)
		
		
		var down_neighbor = room_coord + Vector2i.DOWN
		if grid.has(down_neighbor):
			var corridor: Node2D = level_data.v_corridor.instantiate()
			corridor.position = room_instance.position + Vector2(
				0, grid_cell_size.y / 2.0)
			add_child(corridor)

## 检查当前房间四邻，若已有房间则打通对应方向墙壁
##
## [b]难点说明[/b]：单向打通机制
## 只打通当前房间朝向邻居的墙壁，邻居反向墙壁保持不变
## 这意味着走廊是单向的，锁门后无法原路返回
func connect_rooms(room_coord: Vector2i, room_instance: LevelRoom) -> void:
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]
	for direction in directions:
		var neighbor_coord = room_coord + direction
		if grid.has(neighbor_coord):
			room_instance.open_wall(direction)

## 标记起始房间和终点房间
func select_special_rooms() -> void:
	start_room_coord = Vector2i.ZERO
	end_room_coord = find_farthest_room()
	
	var candidate_coords = grid.keys()
	candidate_coords.erase(start_room_coord)
	candidate_coords.erase(end_room_coord)
	
	if not candidate_coords.is_empty():
		store_room_coord = candidate_coords.pick_random()
	else:
		store_room_coord = Vector2i.MAX
		print("No shop coord")


## 使用欧式距离找到离起点最远的房间（作为终点/主线房）
##
## [b]难点说明[/b]：使用欧式距离而非 BFS 路径距离
## 欧式距离是直线距离，不考虑走廊绕行；BFS 距离更准确但需要额外计算
func find_farthest_room() -> Vector2i:
	var farthest_room_coord := start_room_coord
	var max_dist := 0.0
	for room_coord: Vector2i in grid.keys():
		var dist = start_room_coord.distance_to(room_coord)
		if dist > max_dist:
			max_dist = dist
			farthest_room_coord = room_coord
	return farthest_room_coord


## 创建玩家实例并放置到起始房间的出生点
##
## [b]难点说明[/b]：玩家创建后立即赋值 Global.player_ref
## 敌人等组件通过此全局引用追踪玩家位置
func load_game_selection() -> void:
	player = Global.get_player().instantiate()
	var first_room: LevelRoom = grid[Vector2i.ZERO]
	var spawn_pos: Marker2D = first_room.player_spawn_pos
	add_child(player)
	player.global_position = spawn_pos.global_position
	player.weapon_controller.equip_weapon(Global.selected_weapon)
	Global.player_ref = player

## 根据房间实例反查其在网格中的绝对坐标
##
## [b]难点说明[/b]：反向查找的必要性
## 小地图使用相对坐标（相对于起始房间），但 EventBus 传递的是房间引用
## 需先通过遍历 grid 找到绝对坐标，再减去起始坐标得到相对坐标
func find_coord_from_room(room: LevelRoom) -> Vector2i:
	for coord: Vector2i in grid:
		if grid[coord] == room:
			return coord
	return Vector2i.MAX

## 生命值变化回调，更新 HUD 进度条
##
## [b]难点说明[/b]：TextureProgressBar.value 范围是 0~1（比例）
## 直接用 current/max 计算比例即可
func _on_player_health_updated(current: float, max: float) -> void:
	health_bar.value = current / max

## 玩家进入房间时的信号处理：更新引用 + 小地图 + 锁门 + 生成敌人
##
## [b]难点说明[/b]：四重职责的信号处理
## 1. 更新 current_room 引用（仅在房间变更时）
## 2. 计算相对坐标并通知 MapController 更新小地图
## 3. 对未清理的房间执行锁门
## 4. 锁门后立即通过 enemy_spawner 生成敌人
## 使用 room != current_room 守卫避免同一房间重复触发
func _on_player_room_entered(room: LevelRoom) -> void:
	if room != current_room:
		current_room = room
		
		var absolute_coord: Vector2i = find_coord_from_room(room)
		var relative_coord: Vector2i = absolute_coord - start_room_coord
		map_controller.update_on_room_entered(relative_coord)
		
		if not room.is_cleared:
			room.lock_room()
			enemy_spawner.spawn_enemies(level_data, room)

## 房间清理完成信号回调：解锁当前房间 → 标记已清理 → 在随机位置生成宝箱
##
## [b]模块关系[/b]：
## EnemySpawner → EventBus.on_room_cleared.emit()
## → Arena._on_room_cleared() → unlock_room() + 生成 Chest
## → Chest._on_area_2d_body_entered() → 掉落 Coin → EventBus.on_coin_picked
##
## [b]难点说明[/b]：由 EnemySpawner 在全部敌人被击杀后发射 on_room_cleared
## Arena 监听此信号后执行 unlock_room()，恢复通行
##
## [b]难点说明[/b]：宝箱位置计算流程
## 1. get_free_spawn_position() 返回 TileMap 本地坐标（房间坐标系）
## 2. to_global() 将本地坐标转换为世界坐标
## 3. call_deferred 延迟挂载，确保当前帧结束后再添加到场景树
## 4. 挂载后设置 global_position（此时节点已在树中，坐标计算正确）
func _on_room_cleared() -> void:
	current_room.unlock_room()
	current_room.is_cleared = true
	# 获取房间内随机地砖位置（本地坐标）
	var tile_pos := current_room.get_free_spawn_position()
	# 转换为世界坐标
	var chest_pos := current_room.to_global(tile_pos)
	# 实例化宝箱并延迟挂载（避免在当前帧信号回调中直接修改场景树）
	var chest_instance: Chest = Global.CHEST_SCENE.instantiate()
	call_deferred("add_child", chest_instance)
	chest_instance.global_position = chest_pos
	

## 金币拾取信号回调：播放音效 + 更新金币显示
##
## [b]难点说明[/b]：与 _on_player_health_updated 对称
## 健康值由 on_player_health_updated 信号实时更新 health_bar
## 金币由 on_coin_picked 信号实时更新 total_conins
## 两者均通过 EventBus 信号驱动，保持 UI 与数据层同步
func _on_coin_picked() -> void:
	coin_sound.play()
	# 更新金币总数显示（Global.coins 已由 Coin._on_body_entered 递增）
	total_coins.text = str(Global.coins)
