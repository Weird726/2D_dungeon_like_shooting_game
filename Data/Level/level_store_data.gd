## 商店物品配置，定义单个可售卖物品及其出现概率
extends Resource
class_name  LevelStoreData

## 物品数据引用（如武器、药水等 Resource）
@export var item_data: Resource
## 该物品在商店中出现的概率（0.0 ~ 1.0）
@export var item_prob: float
