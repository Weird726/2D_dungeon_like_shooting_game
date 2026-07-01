## 关卡配置数据，定义地牢的房间数量、尺寸、敌人配置等参数
extends Resource
class_name LevelData

## 每个关卡包含的子区域数量
@export var num_sub_levels := 4
## 每个子区域内的房间总数
@export var num_rooms := 10
## 单个房间的像素尺寸（宽 × 高）
@export var room_size := Vector2(352, 384)
## 房间场景预制体，用于实例化地牢房间
@export var room_scene: PackedScene
## 每个房间生成的最小敌人数量
@export var min_enemies_per_room := 5
## 每个房间生成的最大敌人数量
@export var max_enemies_per_room := 10
## 可选敌人场景池，生成时从中随机抽取
@export var enemy_scenes: Array[PackedScene]
## 商店物品配置列表，定义关卡中可出现的商品
@export var store_data: Array[LevelStoreData]
