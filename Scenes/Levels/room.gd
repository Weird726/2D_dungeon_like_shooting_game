## 地牢房间基类，管理单个房间的地面、墙壁和门的 TileMap 层
##
## [b]模块关系[/b]：
## Arena 持有 LevelRoom 实例（通过 grid 字典），调用 lock/unlock/open_wall
## EnemySpawner 调用 get_free_spawn_position() 获取敌人随机生成位置
## 玩家进入检测区时通过 EventBus 通知 Arena 执行锁门流程
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
## 房间是否已清理（所有敌人被消灭），已清理的房间不再锁门
var is_cleared: bool

## 初始化房间：封闭墙壁 → 缓存地砖 → 隐藏所有门
##
## [b]难点说明[/b]：初始化顺序与可见性继承
## 1. close_all_walls() 必须在 register_tiles() 之前调用
## 2. 门初始化必须在最后，因为场景文件中 Doors 父节点 visible=true（默认），
##    子门有 tile_map_data 会默认渲染，需显式隐藏
## [b]难点说明[/b]：Godot visible 继承机制
##    父节点 visible=false 会阻断所有子节点渲染（无论子节点自身 visible 值）
##    因此不能将 Doors 父节点设为 false，只能逐个隐藏子门
func _ready() -> void:
	close_all_walls()
	register_tiles()
	# 逐个隐藏子门（visible=false + enabled=false）
	# 不能设置 Doors.visible=false，否则 lock_room() 中子门 visible=true 也无效
	for direction in clear_door_nodes:
		clear_door_nodes[direction].visible = false
		clear_door_nodes[direction].enabled = false

## 将 TileMapLayer 中的所有地砖坐标缓存到 tiles 数组
func register_tiles() -> void:
	for tile in tile_data.get_used_cells():
		tiles.append(tile)

## 获取房间内一个随机的空闲地砖位置（本地坐标）
##
## [b]难点说明[/b]：返回的是 TileMap 本地坐标（经 map_to_local 转换后的像素位置）
## 调用方（EnemySpawner）需通过 to_global() 进一步转换为世界坐标
## 使用 pick_random() 从缓存的地砖数组中随机选取，确保位置在可通行区域内
func get_free_spawn_position() -> Vector2:
	var tile_cood: Vector2i = tiles.pick_random()
	return tile_data.map_to_local(tile_cood)

## 在房间内随机生成道具（如箱子、桶等可破坏/可交互物体）
##
## [b]难点说明[/b]：地砖坐标到世界坐标的转换
## tiles 数组存储的是 TileMap 本地坐标（格子索引）
## 需通过 map_to_local() 转换为房间内的像素位置
## 随机选取地砖 + 随机选取道具场景 = 完全随机的道具布局
func create_props(data: LevelData) -> void:
	for i in data.max_props_per_room:
		var tile_coord: Vector2i = tiles.pick_random()
		var tile_pos: Vector2 = tile_data.map_to_local(tile_coord)
		var random_prop: PackedScene = data.props.pick_random()
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
	for direction in clear_door_nodes:
		var wall_door = room_walls[direction]
		var clear_door = clear_door_nodes[direction]
		
		# 仅处理已打通的开口（墙壁被 open_wall 关闭后 enabled == false）
		if wall_door and not wall_door.enabled:
			clear_door.enabled = true
			clear_door.visible = true

## 解锁：关闭所有透明门碰撞和可见性，恢复通行
##
## [b]难点说明[/b]：enabled 与 visible 必须同步关闭
## 若只关 enabled 不关 visible -> 门可见但可穿透（逻辑错误）
## 若只关 visible 不关 enabled -> 门不可见但挡路（物理错误）
func unlock_room() -> void:
	for direction in clear_door_nodes:
		clear_door_nodes[direction].enabled = false
		clear_door_nodes[direction].visible = false

## 打开指定方向的墙壁（当相邻房间打通时调用）
func open_wall(direction: Vector2i) -> void:
	if room_walls.has(direction):
		room_walls[direction].enabled = false

## 关闭所有方向的墙壁（房间初始化时调用）
func close_all_walls() -> void:
	for key in room_walls:
		room_walls[key].enabled = true


## 玩家进入房间检测区域的信号回调
## 通过 EventBus 通知 Arena 更新当前房间并执行锁门逻辑
func _on_player_detector_body_entered(body: Node2D) -> void:
	EventBus.on_player_room_entered.emit(self)
