extends Node

## 用户存档文件路径
var save_path: String = "user://save.json"

## 爆炸特效预制场景，供 create_explosion() 实例化使用
const EXPLOSION_EFFECT_SCENE = preload("uid://hhsw5ccj2s3p")
## 伤害数字文本预制场景，供 create_damage_text() 实例化使用
const DAMAGE_TEXT_SCENE = preload("uid://dksmdpebiv671")
## 敌人生成标记特效预制场景，在敌人出现前播放入场动画
const SPAWN_MARKER_SCENE = preload("uid://bboohpqo6tdh")
## 敌人死亡粒子特效预制场景，死亡时播放粒子爆发动画
const DEAD_PARTICLE_SCENE = preload("uid://c73pc8uwdapr5")
## 受击闪白材质（ShaderMaterial），临时替换敌人精灵材质实现受击视觉反馈
const HIT_MATERIAL = preload("uid://djspx7emtgpys")
const BLOOD_EFFECT_SCENE = preload("uid://ccw5ny12ep13e")
const CHEST_SCENE = preload("uid://der68e5bq56yr")
const STORE_ITEM_SCENE = preload("uid://shcn1g4esyq8")


## 全局设置，存储音量、音效和全屏等用户偏好
var settings: Dictionary = {
	"music": true,
	"sfx": true,
	"fullscreen": true
}

## 全部可选角色场景映射（key 为角色 id，value 为 PackedScene）
var all_players: Dictionary[String, PackedScene] = {
	"Bunny": preload("uid://bmkt5wibg2k55"),
	"Dog": preload("uid://pd4h72eqbo16"),
	"Mouse": preload("uid://dnsjdwshtpqp2"),
	"Cat": preload("uid://bajjniw8jfhwc"),
}

## 全部可选武器场景映射（key 为武器名称，value 为 PackedScene）
var all_weapons: Dictionary[String, PackedScene] = {
	"Ak47": preload("uid://cxdab8nut0a6g"),
	"Mp7": preload("uid://bartsw5ocoyll"),
	"Pistol": preload("uid://jo8ht7pc50mw"),
	"R93": preload("uid://cadvltt3u0qu8"),
	"Spas12": preload("uid://d3pjsry6r4xtr"),
	"Thomson": preload("uid://cseoobyejbqvh"),
	"Uzi": preload("uid://n28dex5w8mxf"),
	"Sword": preload("uid://r28cbjrn6ddt"),
	"Axe": preload("uid://dxh5hbdppbk7i"),
}

## 玩家实例的全局引用，供敌人等组件追踪玩家位置
##
## [b]难点说明[/b]：由 arena.load_game_selection() 在创建玩家后赋值
## 敌人通过 Global.player_ref 获取玩家位置，避免每个敌人单独持有引用
## 玩家死亡（queue_free）后变为 null，敌人需做守卫条件判断
var player_ref: Player
## 当前选中的角色数据（由角色选择界面赋值，未选择时为 null）
var selected_player: PlayerData
## 当前选中的武器数据（由角色选择界面赋值，未选择时为 null）
var selected_weapon: WeaponData
## 玩家当前金币总数，由 Coin 拾取时递增，Arena UI 实时显示
##
## [b]难点说明[/b]：coins 未纳入存档系统
## save_data/load_data 仅处理 settings 字典，coins 每次开局归零
## 若需跨局保留金币，需将 coins 加入存档序列化
var coins: float

## 节点初始化：引擎启动时自动加载磁盘存档（设置项）
func _ready() -> void:
	load_data()

## 根据选中角色 id 从 all_players 中取出对应的 PackedScene
##
## [b]难点说明[/b]：selected_player 可能为 null（如 F6 单独运行 Arena 场景、
## 或用户未选择角色就进入战斗），访问 null.id 会崩溃。
## 调用前需确保 selected_player 已被赋值，或在此处加空值保护。
func get_player() -> PackedScene:
	return all_players[selected_player.id]

## 根据选中武器名称从 all_weapons 中取出对应的 PackedScene
##
## [b]难点说明[/b]：与 get_player() 同理，selected_weapon 可能为 null，
## 访问 null.weapon_name 会崩溃。调用前需确保已赋值或加空值保护。
func get_weapon() -> PackedScene:
	return all_weapons[selected_weapon.weapon_name]

## 在指定位置生成伤害数字文本，带随机偏移防止多次伤害重叠
##
## [b]难点说明[/b]：使用极坐标随机（单位向量 旋转 × 固定半径）计算偏移，
## 确保伤害文本均匀分布在碰撞点周围，避免多个数字完全重叠。
func create_damage_text(value: float, pos: Vector2) -> void:
	var damage: DamageText = DAMAGE_TEXT_SCENE.instantiate()
	get_parent().add_child(damage)
	var random_pos = randf_range(0, TAU)
	damage.global_position = pos + Vector2.RIGHT.rotated(random_pos) * 20
	damage.setup(value)
	var blood = BLOOD_EFFECT_SCENE.instantiate()
	get_parent().add_child(blood)
	blood.global_position = pos

## 在指定位置生成敌人死亡粒子特效并添加到场景树
##
## [b]难点说明[/b]：GPUParticles2D 的 texture 属性需在实例化后动态赋值
## 因为不同敌人使用不同的死亡粒子纹理，无法在预制场景中硬编码
## pos 参数指定粒子生成位置，确保特效出现在敌人死亡位置
func create_dead_particle(texture: Texture2D, pos: Vector2) -> void:
	var particle = DEAD_PARTICLE_SCENE.instantiate() as GPUParticles2D
	get_tree().root.add_child(particle)
	# 设置粒子位置为敌人死亡位置（世界坐标）
	particle.global_position = pos
	particle.texture = texture
	particle.emitting = true

## 在指定世界坐标位置生成爆炸特效并添加到场景树
func create_explosion(pos: Vector2) -> void:
	var explosion: Node2D = EXPLOSION_EFFECT_SCENE.instantiate()
	explosion.global_position = pos
	get_tree().root.add_child(explosion)

## 将当前设置持久化到磁盘
func save_data() -> void:
	var save: Dictionary = settings.duplicate()
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	var json_string: String = JSON.stringify(save)
	file.store_string(json_string)
	file.close()

## 从磁盘加载存档，若文件不存在则使用默认值
func load_data() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	var json: String = file.get_as_text()
	var data: Dictionary = JSON.parse_string(json)
	# 仅覆盖已存在的键，防止存档字段与代码不同步
	for key in data:
		if settings.has(key):
			settings[key] = data[key]
	file.close()
