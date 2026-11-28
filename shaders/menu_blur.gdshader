// 메뉴 뒤 화면 블러 (메뉴). 뒤의 게임 화면을 흐리게만 한다 (어둡게 덮지 않는다)
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float radius = 9.0;

void fragment() {
	vec2 step_px = SCREEN_PIXEL_SIZE * radius;
	vec3 acc = vec3(0.0);
	float n = 0.0;
	for (int x = -4; x <= 4; x++) {
		for (int y = -4; y <= 4; y++) {
			acc += textureLod(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * step_px, 2.0).rgb;
			n += 1.0;
		}
	}
	vec3 blurred = acc / n;
	COLOR = vec4(blurred, 1.0);
}
