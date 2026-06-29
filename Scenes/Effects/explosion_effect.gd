## 爆炸特效，动画播放完毕后自动销毁自身节点
extends AnimatedSprite2D
class_name ExplosionEffect


## 动画播放完成信号回调，销毁特效节点以释放内存
func _on_animation_finished() -> void:
	queue_free()
