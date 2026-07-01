## 地牢房间基类，管理单个房间的地面、墙壁和门的 TileMap 层
extends Node2D
class_name LevelRoom

## 方向到墙壁 TileMapLayer 的映射字典，用于按方向控制墙壁开关
@onready var room_walls: Dictionary[Vector2i, TileMapLayer] = {
	Vector2i.UP:%WallUP, 
	Vector2i.RIGHT:%WallRight,
	Vector2i.DOWN:%WallDown, 
	Vector2i.LEFT:%WallLeft,
}

## 初始化时关闭所有墙壁（房间默认封闭）
func _ready() -> void:
	close_all_walls()

## 打开指定方向的墙壁（当相邻房间打通时调用）
func open_wall(direction: Vector2i) -> void:
	if room_walls.has(direction):
		room_walls[direction].enabled = false

## 关闭所有方向的墙壁（房间初始化时调用）
func close_all_walls() -> void:
	for key in room_walls:
		room_walls[key].enabled = true
