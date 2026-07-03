## 小地图控制器，管理迷你地图上房间格子的创建、显示和玩家位置标记
## 监听玩家进入房间事件，动态揭示已探索的房间并标记当前位置
extends Control
class_name MapController

## 预加载 MapCell 场景，避免每次创建时重复读取磁盘
const MAP_CELL_SCENE: PackedScene = preload("res://Scenes/UI/MapCell/map_cell.tscn")

## 坐标到 MapCell 的映射字典，缓存已创建的格子避免重复创建
var minimap_cells: Dictionary[Vector2i, MapCell] = {}
## 玩家当前所在的格子坐标，用于切换玩家图标位置
var player_coord := Vector2i.MAX
## 单个格子的像素尺寸，首次创建时从 MapCell 实例读取并缓存
##
## [b]难点说明[/b]：延迟初始化
## cell_size 在第一个 MapCell 创建前为 Vector2.ZERO
## 因为 Control 的 size 只有在节点加入场景树后才能正确获取
var cell_size: Vector2

## 玩家进入新房间时的地图更新入口
##
## [b]难点说明[/b]：Get-or-Create 缓存模式
## 先查字典缓存，命中则复用旧格子；未命中则创建新格子
## 避免重复创建相同坐标的 MapCell，同时实现"战争迷雾"揭示效果
func update_on_room_entered(new_room_coord: Vector2i) -> void:
	# 同一房间重复触发时跳过（避免同一帧多次进入）
	if new_room_coord == player_coord:
		return
	
	# 关闭旧位置的玩家图标
	if minimap_cells.has(player_coord):
		minimap_cells[player_coord].set_player_active(false)
	
	# 获取或创建新位置的格子（Get-or-Create 模式）
	var new_cell: MapCell
	if minimap_cells.has(new_room_coord):
		# 已探索过 → 复用缓存的格子
		new_cell = minimap_cells[new_room_coord]
	else:
		# 首次探索 → 创建新格子并缓存
		new_cell = create_map_cell(new_room_coord)
	
	# 更新玩家坐标并激活新位置的玩家图标
	player_coord = new_room_coord
	new_cell.set_player_active(true)

## 创建指定坐标的 MapCell 并计算其在小地图上的像素位置
##
## [b]难点说明[/b]：网格坐标到像素坐标的转换
## 小地图以自身中心为原点，格子按网格坐标排列
## 公式：position = (容器尺寸/2) + (格子坐标×格子尺寸) - (格子尺寸/2)
## 使格子在容器内居中显示，且按网格规则排列
func create_map_cell(coord: Vector2i) -> MapCell:
	# 实例化 MapCell 场景并强制转换为 MapCell 类型
	var new_cell: MapCell = MAP_CELL_SCENE.instantiate() as MapCell
	
	# 存入缓存字典并加入场景树
	minimap_cells[coord] = new_cell
	add_child(new_cell)
	
	# 首次创建时缓存格子尺寸（后续格子复用此值定位）
	if cell_size == Vector2.ZERO:
		cell_size = new_cell.size
	
	# 网格坐标 × 格子尺寸 = 相对偏移量
	var relative_pos := Vector2(coord.x * cell_size.x, coord.y * cell_size.y)
	# 居中排列：容器中心 + 偏移 - 半个格子尺寸（使格子中心对齐网格点）
	new_cell.position = (size / 2.0) + relative_pos - (cell_size / 2.0)
	return new_cell

## 重置小地图：销毁所有格子并恢复初始状态
func reset() -> void:
	# 逐个释放格子节点（延迟到帧末安全删除）
	for cell: MapCell in minimap_cells.values():
		cell.queue_free()
	
	# 清空缓存字典并重置状态变量
	minimap_cells.clear()
	player_coord = Vector2i.MAX
	cell_size = Vector2.ZERO
