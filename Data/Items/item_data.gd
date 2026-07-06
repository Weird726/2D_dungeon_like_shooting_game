## 道具数据资源，定义商店道具的所有配置属性
##
## [b]模块关系[/b]：
## StoreItem 持有 ItemData 引用，通过 setup() 初始化外观和价格
## ItemData 为纯数据层（Resource），与场景逻辑解耦
extends Resource
class_name ItemData

## 道具图标纹理，显示在商店 UI 中
@export var icon: Texture2D
## 道具唯一标识符，用于 buy_item() 中 match 判断道具类型
@export var id: String
## 道具显示名称（预留，当前未在 UI 中使用）
@export var name: String
## 道具效果数值（如药水的恢复量），传递给对应组件方法
@export var value: float
## 道具购买价格（金币），显示在商店价格标签中
@export var price: float
## 道具稀有度，决定商店中道具光晕颜色
##
## [b]难点说明[/b]：稀有度与光晕颜色映射
## "Common" → common_glow（白色），"Rare" → rare_glow（蓝色），"Epic" → epic_glow（紫色）
## 由 StoreItem.get_rarity_color() 根据此值返回对应颜色
@export_enum("Common", "Rare", "Epic") var rarity = "Common"
## 道具描述文本（多行），预留用于商店悬浮提示面板
@export_multiline var description: String
