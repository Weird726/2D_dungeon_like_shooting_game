extends Node

#获取效果的节点位置，用于过度场景效果使用
@onready var effect: ColorRect = %Effect

#创建一个过度路径函数用于调用属性实现过度效果使用
func transition_to(scene_path: String) -> void:
#创建一个tween(渐变)的变量，并绑定create_tween()这个节点用于调用属性
	var tween := create_tween()
#访问补间动画并调用它的属性，用于实现渐变效果
#并且依次按照顺序访问 材质组->着色器->参数->进度 (注意没有自动补全功能，需要写对)
#值为1.0,等待时间为1.0秒
	tween.tween_property(effect.material, "shader_parameter/progress",1.0, 1.0)
#等待效果完成（等待孪生体创建完成)
	await tween.finished
#访问场景树，调用更改场景文件方法,并传入场景路径
	get_tree().change_scene_to_file(scene_path)
#创建过度效果赋值于渐变
	tween = create_tween()
#调用渐变属性，用于反转，结束过度，最终值为0.0，时间为1.0
	tween.tween_property(effect.material, "shader_parameter/progress", 0.0, 1.0)
