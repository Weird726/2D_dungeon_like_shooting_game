extends Node

## 菱形遮罩 ColorRect，用于播放场景过渡动画
@onready var effect: ColorRect = %Effect

## 使用菱形遮罩过渡到指定场景。[br]
## [br]
## 过渡流程：进入遮罩 → 切换场景 → 退出遮罩。[br]
## [param scene_path] 目标场景的资源路径。
func transition_to(scene_path: String) -> void:
	var tween: Tween = create_tween()
	# 过渡进入：shader progress 0→1，菱形遮罩覆盖全屏
	tween.tween_property(effect.material, "shader_parameter/progress", 1.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
	# 过渡退出：shader progress 1→0，菱形遮罩消退
	tween = create_tween()
	tween.tween_property(effect.material, "shader_parameter/progress", 0.0, 1.0)
