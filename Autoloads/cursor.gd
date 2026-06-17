extends CanvasLayer

## 自定义光标精灵，替代系统默认鼠标指针
@onready var sprite: Sprite2D = $Sprite

## 隐藏系统默认鼠标指针，改由自定义精灵跟随鼠标显示
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

## 每帧将光标精灵位置同步到鼠标位置
func _process(delta: float) -> void:
	sprite.position = get_viewport().get_mouse_position()
