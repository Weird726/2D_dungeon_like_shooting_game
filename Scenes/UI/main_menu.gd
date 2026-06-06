extends Control
#为UI创建一个类名用于背景功能调用各个控件
class_name MainMenu

#引入节点，目的控制按钮的动画效果引入参数
@onready var main_buttons: Control = $MainButtons
@onready var settings_buttons: Control = $SettingsButtons

#开始按钮的信号链接
func _on_play_button_pressed() -> void:
#调用过度方法,并写入新场景路径用于传送到新场景
	Transition.transition_to("res://Scenes/UI/CharacterSelection/character_selection.tscn")


#设置按钮的信号链接
func _on_settings_button_pressed() -> void:
#创建一个渐变类，用于出发设置按钮的渐变效果
	var tween := create_tween()
#设置渐变属性，在其间输入信号位置，并对其全局位置属性进行位置数据的输入
#用于实现设置按钮被点击后进行Y值竖向进行的动画效果实现
	tween.tween_property(main_buttons,"global_position:y",350,0.2)
	#在渐变库中调用渐变时间间隔来实现延迟效果
	tween.tween_interval(0.1)
#设置渐变属性，在其间输入信号位置，并对其全局位置属性进行位置数据的输入
#用于实现设置按钮被点击后进行X值横向移动动画效果的实现
	tween.tween_property(settings_buttons,"global_position:x",145,0.3)


#退出按钮的信号链接
func _on_quit_button_pressed() -> void:
	pass # Replace with function body.


#音乐按钮的信号链接
func _on_music_button_pressed() -> void:
	pass # Replace with function body.


#音效按钮的信号链接
func _on_sfx_button_pressed() -> void:
	pass # Replace with function body.


#窗口按钮的信号链接
func _on_window_button_pressed() -> void:
	pass # Replace with function body.


#返回按钮的信号链接
func _on_back_button_pressed() -> void:
#创建一个渐变类，用于出发设置按钮的渐变效果
	var tween := create_tween()
#设置渐变属性，在其间输入信号位置，并对其全局位置属性进行位置数据的输入
#用于实现设置按钮被点击后进行X值横向移动动画效果的实现
	tween.tween_property(settings_buttons,"global_position:x",558,0.3)
#在渐变库中调用渐变时间间隔来实现延迟效果
	tween.tween_interval(0.1)
#设置渐变属性，在其间输入信号位置，并对其全局位置属性进行位置数据的输入
#用于实现设置按钮被点击后进行Y值竖向进行的动画效果实现
	tween.tween_property(main_buttons,"global_position:y",115,0.2)
