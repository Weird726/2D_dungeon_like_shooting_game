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

## 地牢房间坐标网格，存储每个坐标位置的房间信息
var grid: Dictionary[Vector2i, LevelRoom] = {}
## 起始房间坐标（玩家出生点）
var start_room_coord: Vector2i
## 终点房间坐标（主线目标或出口）
var end_room_coord: Vector2i
## 单元格尺寸 = 房间尺寸 + 走廊尺寸，用于坐标到像素位置的换算
var grid_cell_size: Vector2i


## 监听全局事件总线，当玩家生命值变化时更新 HUD
func _ready() -> void:
	# 进入场景时切换全局光标为当前场景专用光标
	Cursor.sprite.texture = arena_cursor
	EventBus.on_player_health_updated.connect(_on_player_health_updated)
	
	# 计算单元格尺寸：房间宽高 + 走廊宽高，使房间之间留出走廊空间
	grid_cell_size = Vector2i(
		level_data.room_size.x + level_data.corridor_size.x,
		level_data.room_size.y + level_data.corridor_size.y,
	)
	
	generate_level_layout()
	select_special_rooms()
	create_rooms()
	create_corridors()
	load_game_selection()

## 使用随机游走算法生成地牢房间布局
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
	
	while grid.size() < level_data.num_rooms:
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
		
		if not grid.has(next_coord):
			grid[next_coord] = null
	
	for key: Vector2i in grid.keys():
		print(key)

## 遍历坐标网格，实例化房间场景并放置到对应位置
##
## [b]难点说明[/b]：使用 await 实现逐个房间生成的动画效果
## 每生成一个房间暂停 0.5 秒，让玩家看到建造过程
func create_rooms() -> void:
	print("Creating rooms...")
	for room_coord: Vector2i in grid.keys():
		var room_instance: LevelRoom = level_data.room_scene.instantiate()
		room_instance.position = room_coord * grid_cell_size
		add_child(room_instance)
		
		# 将生成的房间实例存入网格字典，替换之前的 null 占位
		grid[room_coord] = room_instance
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

## 检查当前房间的四个相邻坐标，若已有房间则打通墙壁
func connect_rooms(room_coord: Vector2i, room_instance: LevelRoom) -> void:
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]
	for direction in directions:
		var neighbor_coord = room_coord + direction
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
func load_game_selection() -> void:
	var player: Player = Global.get_player().instantiate()
	# 获取起始房间实例
	var first_room: LevelRoom = grid[Vector2i.ZERO]
	# 获取房间内的玩家出生点标记
	var spawn_pos: Marker2D = first_room.player_spawn_pos
	add_child(player)
	# 将玩家放置到出生点的实际世界坐标
	player.global_position = spawn_pos.global_position
	# 角色实例化后再装备武器，因为武器控制器是角色的子节点
	player.weapon_controller.equip_weapon()


## 生命值变化回调，更新进度条显示
##
## [b]难点说明[/b]：TextureProgressBar.value 范围是 0~1（比例），
## 而非 0~100（百分比），因此直接用 current/max 计算比例。
## 若进度条配置为 0~100，则需乘以 100。
func _on_player_health_updated(current: float, max: float) -> void:
	health_bar.value = current / max
