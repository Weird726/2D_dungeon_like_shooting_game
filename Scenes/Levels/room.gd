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

## 初始化时关闭所有墙壁（房间默认封闭）
func _ready() -> void:
	#close_all_walls()
	register_tiles()

## 测试用函数
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		lock_room()
	if event.is_action_pressed("ui_cancel"):
		unlock_room()

## 将 TileMapLayer 中的所有地砖坐标缓存到 tiles 数组
func register_tiles() -> void:
	# 遍历地砖层获取所有已绘制的地砖坐标
	for tile in tile_data.get_used_cells():
		tiles.append(tile)

## 锁门：在所有已打通的开口处启用透明门碰撞，阻止玩家出入
##
## [b]难点说明[/b]：双层门系统
## room_walls 控制墙壁可见性，clear_door_nodes 控制碰撞体
## 锁门时墙壁已关闭（open_wall），只需启用透明门碰撞即可封路
func lock_room() -> void:
	for direction in clear_door_nodes:
		var wall_door = room_walls[direction]
		var clear_door = clear_door_nodes[direction]
		
		if wall_door and not wall_door.enabled:
			clear_door.enabled = true

## 解锁：关闭所有透明门碰撞，恢复通行
func unlock_room() -> void:
	# 遍历所有方向，关闭透明门碰撞
	for direction in clear_door_nodes:
		clear_door_nodes[direction].enabled = false

## 打开指定方向的墙壁（当相邻房间打通时调用）
func open_wall(direction: Vector2i) -> void:
	if room_walls.has(direction):
		room_walls[direction].enabled = false

## 关闭所有方向的墙壁（房间初始化时调用）
func close_all_walls() -> void:
	for key in room_walls:
		room_walls[key].enabled = true
