shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (UV.y > progress) {
		color.a = 0.0;
	}

	COLOR = color;
}