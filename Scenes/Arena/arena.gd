extends Node2D
class_name Arena

## 代替原有光标的新精灵图
@export var arena_cursor: Texture2D
## 关卡配置数据引用，控制房间数量、尺寸、敌人配置等
@export var level_data: LevelData

## 生命值进度条，显示当前/最大生命值的比例
@onready var health_bar: TextureProgressBar = %HealthBar
## 魔法值进度条，显示当前/最大魔法值的比例
@onready var mana_bar: TextureProgressBar = %ManaBar
## 小地图控制器引用，用于在玩家进入房间时更新地图显示
@onready var map_controller: MapController = $UI/MapController

## 地牢房间坐标网格，存储每个坐标位置的房间信息
var grid: Dictionary[Vector2i, LevelRoom] = {}
## 起始房间坐标（玩家出生点）
var start_room_coord: Vector2i
## 终点房间坐标（主线目标或出口）
var end_room_coord: Vector2i
## 单元格尺寸 = 房间尺寸 + 走廊尺寸，用于坐标到像素位置的换算
var grid_cell_size: Vector2i

## 当前玩家实例引用，由 load_game_selection() 创建
var player: Player
## 玩家当前所在的房间引用，由 _on_player_room_entered() 更新
var current_room: LevelRoom


## 场景初始化：连接信号 → 生成地牢 → 放置玩家
##
## [b]难点说明[/b]：初始化管线顺序
## 必须严格按 布局→房间→走廊→玩家 的顺序执行
## 因为后续步骤依赖前序步骤的产出（如玩家放置依赖房间已存在）
func _ready() -> void:
	# 进入场景时切换全局光标为当前场景专用光标
	Cursor.sprite.texture = arena_cursor
	# 连接全局事件总线信号
	EventBus.on_player_health_updated.connect(_on_player_health_updated)
	EventBus.on_player_room_entered.connect(_on_player_room_entered)
	
	# 计算单元格尺寸：房间宽高 + 走廊宽高，使房间之间留出走廊空间
	grid_cell_size = Vector2i(
		level_data.room_size.x + level_data.corridor_size.x,
		level_data.room_size.y + level_data.corridor_size.y,
	)
	
	# 按管线顺序执行地牢生成各阶段
	generate_level_layout()   # 1. 随机生成房间坐标布局
	select_special_rooms()    # 2. 标记起点/终点特殊房间
	create_rooms()            # 3. 实例化房间场景并打通相邻墙壁
	create_corridors()        # 4. 在相邻房间之间生成走廊视觉连接
	load_game_selection()     # 5. 创建玩家并放置到起始房间
	
	# 标记起始房间为已清理，防止玩家出生在检测区内时误触发锁门
	var first_room: LevelRoom = grid[Vector2i.ZERO]
	first_room.is_cleared = true

## 测试用输入处理：Esc 键手动解锁当前房间
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# 解锁当前房间的门并标记为已清理
		current_room.unlock_room()
		current_room.is_cleared = true

## 使用随机游走算法生成地牢房间布局
##
## [b]难点说明[/b]：算法核心是随机游走 + 冲突重试
## 50% 概率从已有房间中随机选起点（避免线性链），否则从当前房间扩展
## 若目标位置已被占用，最多重试 10 次寻找空位
func generate_level_layout() -> void:
	grid.clear()
	
	print("Creating layout...")
	# 从原点开始生成第一个房间
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
		# 冲突重试循环：目标位置已占用时重新选方向
		while grid.has(next_coord) and attempts < 10:
			random_direction = directions.pick_random()
			next_coord = current_coord + random_direction
			attempts += 1
		
		# 找到空位则注册新房间坐标
		if not grid.has(next_coord):
			grid[next_coord] = null
	
	for key: Vector2i in grid.keys():
		print(key)

## 遍历坐标网格，实例化房间场景并放置到对应位置
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
		# 按关卡配置在房间内随机生成道具（箱子、桶等）
		room_instance.create_props(level_data)
		
		# 将生成的房间实例存入网格字典，替换之前的 null 占位
		grid[room_coord] = room_instance
		# 检查并打通与相邻房间的墙壁
		connect_rooms(room_coord, room_instance)

## 在相邻房间之间生成走廊连接节点
##
## [b]难点说明[/b]：走廊位置改为偏移计算（不再取中点）
## 水平走廊：从房间右边缘偏移半个单元格宽度
## 垂直走廊：从房间下边缘偏移半个单元格高度
func create_corridors() -> void:
	print("Creating corridors...")
	for room_coord: Vector2i in grid.keys():
		var room_instance: LevelRoom = grid[room_coord]
		
		# 创建向右连接
		var right_neighbor = room_coord + Vector2i.RIGHT
		if grid.has(right_neighbor):
			var corridor: Node2D = level_data.h_corridor.instantiate()
			# 走廊偏移计算：从房间边缘偏移半个单元格尺寸
			corridor.position = room_instance.position + Vector2(
				grid_cell_size.x / 2.0, 0)
			add_child(corridor)
		
		
		# 创建向下连接
		var down_neighbor = room_coord + Vector2i.DOWN
		if grid.has(down_neighbor):
			var corridor: Node2D = level_data.v_corridor.instantiate()
			# 走廊偏移计算：从房间边缘偏移半个单元格尺寸
			corridor.position = room_instance.position + Vector2(
				0, grid_cell_size.y / 2.0)
			add_child(corridor)

## 检查当前房间的四个相邻坐标，若已有房间则打通对应方向墙壁
##
## [b]难点说明[/b]：单向打通机制
## 只打通当前房间朝向邻居的墙壁，邻居朝向当前房间的墙壁保持不变
## 例如房间B在A右侧：B的左墙被打通，但A的右墙仍然封闭
## 这意味着走廊是单向的，锁门后无法原路返回
func connect_rooms(room_coord: Vector2i, room_instance: LevelRoom) -> void:
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]
	for direction in directions:
		var neighbor_coord = room_coord + direction
		# 仅当邻居坐标已有房间时才打通墙壁
		if grid.has(neighbor_coord):
			room_instance.open_wall(direction)

## 从已有房间中挑选特殊房间（如起始点、主线房）
func select_special_rooms() -> void:
	# 起始房间固定为原点（与生成算法的起点一致）
	start_room_coord = Vector2i.ZERO
	end_room_coord = find_farthest_room()
	print("Start: %s" % start_room_coord)
	print("End: %s" % end_room_coord)

## 使用 欧式距离找到离起点最远的房间（作为终点/主线房）
##
## [b]难点说明[/b]：使用欧式距离而非 BFS 路径距离
## 欧式距离是直线距离，不考虑走廊绕行；BFS 距离更准确但需要额外计算
func find_farthest_room() -> Vector2i:
	var farthest_room_coord := start_room_coord
	var max_dist := 0.0
	# 遍历所有房间坐标，记录最大距离对应的坐标
	for room_coord: Vector2i in grid.keys():
		var dist = start_room_coord.distance_to(room_coord)
		if dist > max_dist:
			max_dist = dist
			farthest_room_coord = room_coord
	return farthest_room_coord


## 从全局单例读取选中的角色场景并实例化，放置到起始房间的出生点标记位置
##
## [b]难点说明[/b]：玩家创建后立即赋值 Global.player_ref
## 敌人等组件通过此全局引用追踪玩家位置
func load_game_selection() -> void:
	player = Global.get_player().instantiate()
	# 获取起始房间实例
	var first_room: LevelRoom = grid[Vector2i.ZERO]
	# 获取房间内的玩家出生点标记
	var spawn_pos: Marker2D = first_room.player_spawn_pos
	add_child(player)
	# 将玩家放置到出生点的实际世界坐标
	player.global_position = spawn_pos.global_position
	# 角色实例化后再装备武器，因为武器控制器是角色的子节点
	player.weapon_controller.equip_weapon()
	# 将玩家实例存入全局单例，供敌人追踪等组件使用
	Global.player_ref = player

## 根据房间实例反查其在网格中的绝对坐标
##
## [b]难点说明[/b]：反向查找的必要性
## 小地图使用相对坐标（相对于起始房间），但 EventBus 传递的是房间引用
## 因此需要先通过遍历 grid 找到绝对坐标，再减去起始坐标得到相对坐标
func find_coord_from_room(room: LevelRoom) -> Vector2i:
	# 线性遍历网格字典，匹配房间引用
	for coord: Vector2i in grid:
		if grid[coord] == room:
			return coord
	# 未找到时返回 Vector2i.MAX 作为哨兵值
	return Vector2i.MAX

## 生命值变化回调，更新进度条显示
##
## [b]难点说明[/b]：TextureProgressBar.value 范围是 0~1（比例），
## 而非 0~100（百分比），因此直接用 current/max 计算比例。
## 若进度条配置为 0~100，则需乘以 100。
func _on_player_health_updated(current: float, max: float) -> void:
	health_bar.value = current / max

## 玩家进入房间时的锁门处理 + 小地图更新
##
## [b]难点说明[/b]：三重职责的信号处理
## 1. 更新 current_room 引用（仅在房间变更时）
## 2. 计算相对坐标并通知 MapController 更新小地图
## 3. 对未清理的房间执行锁门
## 使用 room != current_room 守卫避免同一房间重复触发
func _on_player_room_entered(room: LevelRoom) -> void:
	# 仅当房间实际变更时才执行后续逻辑
	if room != current_room:
		current_room = room
		
		# 绝对坐标 → 相对坐标（以起始房间为原点）
		var absolute_coord: Vector2i = find_coord_from_room(room)
		var relative_coord: Vector2i = absolute_coord - start_room_coord
		# 通知小地图控制器揭示新房间
		map_controller.update_on_room_entered(relative_coord)
		
		# 未清理的房间进入时立即锁门，阻止玩家离开
		if not room.is_cleared:
			room.lock_room()
