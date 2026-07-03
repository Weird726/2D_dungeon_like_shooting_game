## 小地图格子单元，显示单个房间的可视化状态和玩家位置标记
## 每个 MapCell 对应地牢中的一个房间，通过玩家图标标记当前位置
extends Control
class_name MapCell

## 玩家位置指示图标，通过可见性切换标记玩家是否在此房间
@onready var player_icon: TextureRect = $PlayerIcon

## 初始化时隐藏玩家图标（房间默认未探索/非当前位置）
func _ready() -> void:
	set_player_active(false)

## 设置玩家是否在此房间（控制玩家图标的可见性）
func set_player_active(value: bool) -> void:
	player_icon.visible = value
