## 商店道具实体，玩家靠近后按确认键购买
##
## [b]模块关系[/b]：
## ItemData → StoreItem.setup() 初始化道具外观/价格
## StoreItem.buy_item() → Global.player_ref.health_component.heal() 执行治疗效果
## StoreItem → queue_free() 购买后销毁自身
extends Area2D
class_name StoreItem

## 普通稀有度光晕颜色（通常为白色）
@export var common_glow: Color
## 稀有稀有度光晕颜色（通常为蓝色）
@export var rare_glow: Color
## 史诗稀有度光晕颜色（通常为紫色）
@export var epic_glow: Color

## 道具精灵，显示 ItemData 中配置的图标
@onready var sprite: Sprite2D = $Sprite
## 光晕精灵，通过 self_modulate 显示稀有度对应颜色
@onready var glow: Sprite2D = $Glow
## 价格标签（RichTextLabel），支持 BBCode 格式显示金币图标 + 价格数字
@onready var price: RichTextLabel = $Price

## 当前道具的数据引用（由 setup() 赋值）
var data: ItemData
## 玩家是否在检测范围内（可购买状态），由 _on_body_entered/exited 控制
var can_buy_item: bool

## 初始化商店道具：设置图标、光晕颜色、价格标签
##
## [b]难点说明[/b]：RichTextLabel BBCode 价格格式
## 使用 [img=10] 标签嵌入金币图标（10 像素宽），%s 占位符替换为价格数值
## 必须确保 Price 节点的 bbcode_enabled = true，否则标签不会被解析
func setup(item_data: ItemData) -> void:
	data = item_data
	# 设置道具图标纹理（从 ItemData.icon 读取）
	sprite.texture = data.icon
	# 根据稀有度设置光晕颜色（通过 self_modulate 叠加着色）
	glow.self_modulate = get_rarity_color()
	# 格式化价格标签：金币图标 + 价格数值
	price.text = "[code][img=10]Sprites/coin.png[/img][/code] %s" % data.price

## 购买道具：根据道具 ID 执行对应效果，然后销毁自身
##
## [b]难点说明[/b]：match 分支扩展性
## 当前仅支持 "Potion"（药水恢复），新增道具类型需在此添加 match 分支
## 购买后立即 queue_free()，防止重复购买
func buy_item() -> void:
	if not data: return
	if Global.coins < data.price: return
	
	
	match data.id:
		"Potion":
			# 药水效果：调用玩家生命组件的治疗方法，恢复 value 点生命值
			Global.player_ref.health_component.heal(data.value)
	
	Global.coins -= data.price
	queue_free()
	#更新ui的事件总线
	EventBus.on_coin_picked.emit()

## 输入检测：玩家按确认键且处于可购买范围时执行购买
##
## [b]难点说明[/b]：_input vs _unhandled_input
## _input 在所有节点处理前捕获输入，适合全局快捷键
## ui_accept 默认绑定 Enter/空格键
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and can_buy_item:
		buy_item()

## 根据道具稀有度返回对应光晕颜色
##
## [b]难点说明[/b]：match 返回值模式
## GDScript 的 match 可直接 return 表达式，无需 break
## 未匹配到任何稀有度时返回白色（Color.WHITE）作为兜底
func get_rarity_color() -> Color:
	match data.rarity:
		"Common":
			return common_glow
		"Rare":
			return rare_glow
		"Epic":
			return epic_glow
	return Color.WHITE

## 玩家进入检测区域：设为可购买状态
func _on_body_entered(body: Node2D) -> void:
	can_buy_item = true


## 玩家离开检测区域：设为不可购买状态
func _on_body_exited(body: Node2D) -> void:
	can_buy_item = false
