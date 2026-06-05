shader_type canvas_item;

// 创建一个统一的浮点数速度变量用于控制背景的移动
uniform float speed = 0.5;

void vertex() {
	// 每个像素点的横轴X减去速度乘以时间用于横轴X的移动
	UV.x -= speed * TIME;
	// 每个像素点的竖轴Y加上速度乘以时间用于竖轴Y的移动
	UV.y += speed * TIME;
}
