shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float reveal_start_x : hint_range(0.0, 1.0) = 0.25;
uniform float reveal_end_x : hint_range(0.0, 1.0) = 0.75;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	float reveal_x = mix(reveal_start_x, reveal_end_x, progress);

	if (UV.x > reveal_x) {
		color.a = 0.0;
	}

	COLOR = color;
}