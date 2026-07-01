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


## 监听全局事件总线，当玩家生命值变化时更新 HUD
func _ready() -> void:
	# 进入场景时切换全局光标为当前场景专用光标
	Cursor.sprite.texture = arena_cursor
	EventBus.on_player_health_updated.connect(_on_player_health_updated)
	
	generate_level_layout()
	select_special_rooms()
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

## 从已有房间中挑选特殊房间（如起始点、主线房）
func select_special_rooms() -> void:
	pass

## 从全局单例读取选中的角色场景并实例化，然后装备选中的武器
func load_game_selection() -> void:
	var player: Player = Global.get_player().instantiate()
	add_child(player)
	# 角色实例化后再装备武器，因为武器控制器是角色的子节点
	player.weapon_controller.equip_weapon()


## 生命值变化回调，更新进度条显示
##
## [b]难点说明[/b]：TextureProgressBar.value 范围是 0~1（比例），
## 而非 0~100（百分比），因此直接用 current/max 计算比例。
## 若进度条配置为 0~100，则需乘以 100。
func _on_player_health_updated(current: float, max: float) -> void:
	health_bar.value = current / max
