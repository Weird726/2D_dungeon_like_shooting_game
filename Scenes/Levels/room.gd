## 地牢房间基类，管理单个房间的地面、墙壁和门的 TileMap 层
extends Node2D
class_name LevelRoom

## 玩家出生点标记，决定玩家实例化后的初始位置
@onready var player_spawn_pos: Marker2D = $PlayerSpawnPos
## 房间地面 TileMap 层，用于获取地砖坐标供敌人/物品生成使用
@onready var tile_data: TileMapLayer = $TileData

## 方向到墙壁 TileMapLayer 的映射字典，用于按方向控制墙壁开关
@onready var room_walls: Dictionary[Vector2i, TileMapLayer] = {
	Vector2i.UP:%WallUP, 
	Vector2i.RIGHT:%WallRight,
	Vector2i.DOWN:%WallDown, 
	Vector2i.LEFT:%WallLeft,
}

## 方向到透明门 TileMapLayer 的映射字典，锁门时启用碰撞阻挡玩家出入
@onready var clear_door_nodes: Dictionary[Vector2i, TileMapLayer] = {
	Vector2i.UP:$Doors/DoorUP, 
	Vector2i.RIGHT:$Doors/DoorRight,
	Vector2i.DOWN:$Doors/DoorDown, 
	Vector2i.LEFT:$Doors/DoorLeft,
}

## 缓存的地砖坐标数组，用于快速遍历房间内的所有地砖位置
var tiles: Array[Vector2i]
## 房间是否已清理（所有敌人被消灭）
var is_cleared: bool

## 初始化房间：先封闭所有墙壁，再缓存地砖坐标
##
## [b]难点说明[/b]：初始化顺序
## close_all_walls() 必须在 register_tiles() 之前调用
## 确保房间初始状态为全封闭，后续由 connect_rooms() 按需打通
func _ready() -> void:
	# 封闭所有方向的墙壁，使房间默认处于完全封闭状态
	close_all_walls()
	# 缓存地砖坐标供后续敌人/物品生成使用
	register_tiles()

## 将 TileMapLayer 中的所有地砖坐标缓存到 tiles 数组
func register_tiles() -> void:
	# 遍历地砖层获取所有已绘制的地砖坐标
	for tile in tile_data.get_used_cells():
		tiles.append(tile)

## 在房间内随机生成道具（如箱子、桶等可破坏/可交互物体）
##
## [b]难点说明[/b]：地砖坐标到世界坐标的转换
## tiles 数组存储的是 TileMap 本地坐标（格子索引）
## 需通过 map_to_local() 转换为房间内的像素位置
## 随机选取地砖 + 随机选取道具场景 = 完全随机的道具布局
func create_props(data: LevelData) -> void:
	# 按配置的最大道具数量循环生成
	for i in data.max_props_per_room:
		# 从缓存的地砖坐标中随机选取一个位置
		var tile_coord: Vector2i = tiles.pick_random()
		# TileMap 本地坐标 -> 房间内的像素位置
		var tile_pos: Vector2 = tile_data.map_to_local(tile_coord)
		# 从道具场景池中随机抽取一个预制体
		var random_prop: PackedScene = data.props.pick_random()
		# 实例化道具并放置到选定的地砖位置
		var instance: Area2D = random_prop.instantiate()
		instance.position = tile_pos
		add_child(instance)

## 锁门：在所有已打通的开口处启用透明门碰撞和可见性，阻止玩家出入
##
## [b]难点说明[/b]：双层门系统的可见性分离
## TileMapLayer 的 enabled 仅控制碰撞/数据激活，不控制渲染
## visible 继承自 CanvasItem，控制实际绘制
## 因此锁门需同时设置 enabled = true（碰撞）和 visible = true（渲染）
## 且只在有开口的方向（wall_door.enabled == false）才显示门
func lock_room() -> void:
	# 遍历四个方向的门节点
	for direction in clear_door_nodes:
		var wall_door = room_walls[direction]
		var clear_door = clear_door_nodes[direction]
		
		# 仅处理已打通的开口（墙壁被 open_wall 关闭后 enabled == false）
		if wall_door and not wall_door.enabled:
			# 启用透明门碰撞体，阻挡玩家通过
			clear_door.enabled = true
			# 显示透明门精灵，提供视觉封锁反馈
			clear_door.visible = true

## 解锁：关闭所有透明门碰撞和可见性，恢复通行
##
## [b]难点说明[/b]：enabled 与 visible 必须同步关闭
## 若只关 enabled 不关 visible -> 门可见但可穿透（逻辑错误）
## 若只关 visible 不关 enabled -> 门不可见但挡路（物理错误）
func unlock_room() -> void:
	# 遍历所有方向，同步关闭碰撞和可见性
	for direction in clear_door_nodes:
		clear_door_nodes[direction].enabled = false
		clear_door_nodes[direction].visible = false

## 打开指定方向的墙壁（当相邻房间打通时调用）
func open_wall(direction: Vector2i) -> void:
	# 安全检查：确认方向存在对应墙壁后再关闭
	if room_walls.has(direction):
		room_walls[direction].enabled = false

## 关闭所有方向的墙壁（房间初始化时调用）
func close_all_walls() -> void:
	# 遍历所有方向，启用墙壁碰撞和可见性
	for key in room_walls:
		room_walls[key].enabled = true


## 玩家进入房间检测区域的信号回调
## 通过 EventBus 通知 Arena 更新当前房间并执行锁门逻辑
func _on_player_detector_body_entered(body: Node2D) -> void:
	# 向全局事件总线发射玩家进入房间事件，携带当前房间引用
	EventBus.on_player_room_entered.emit(self)
