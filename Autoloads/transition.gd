extends Node

## 场景过渡效果节点
@onready var effect: ColorRect = %Effect

## 使用菱形遮罩过渡到指定场景
func transition_to(scene_path: String) -> void:
	var tween := create_tween()
	# 过渡进入：shader progress 0→1
	tween.tween_property(effect.material, "shader_parameter/progress", 1.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
	# 过渡退出：shader progress 1→0
	tween = create_tween()
	tween.tween_property(effect.material, "shader_parameter/progress", 0.0, 1.0)
