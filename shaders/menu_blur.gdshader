// 메뉴 뒤 화면 블러 (일시정지 메뉴). 뒤의 게임 화면을 흐리게 하고 어둡게 덮어 내용을 읽을 수 없게 한다
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float radius = 9.0;
uniform vec4 tint : source_color = vec4(0.05, 0.04, 0.08, 0.85);

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
	COLOR = vec4(mix(blurred, tint.rgb, tint.a), 1.0);
}
