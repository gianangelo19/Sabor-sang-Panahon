shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 3.0;
uniform float color_levels : hint_range(2.0, 64.0, 1.0) = 28.0;
uniform float scanline_strength : hint_range(0.0, 1.0, 0.01) = 0.07;
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform float warp_strength : hint_range(0.0, 0.08, 0.001) = 0.004;
uniform float noise_strength : hint_range(0.0, 0.2, 0.001) = 0.006;
uniform float edge_strength : hint_range(0.0, 1.0, 0.01) = 0.16;
uniform float brightness : hint_range(0.5, 1.5, 0.01) = 1.12;
uniform float saturation : hint_range(0.0, 2.0, 0.01) = 1.08;
uniform vec3 warm_tint = vec3(1.07, 1.02, 0.92);

float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

float luma(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered_uv = uv * 2.0 - 1.0;
	float radius = dot(centered_uv, centered_uv);
	uv += centered_uv * radius * warp_strength;
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel_count = screen_size / pixel_size;
	vec2 pixelated_uv = (floor(uv * pixel_count) + 0.5) / pixel_count;
	vec3 color = texture(screen_texture, pixelated_uv).rgb;
	// Clamp to fix HDR blowout / blue splotches
	color = clamp(color, 0.0, 1.0);
	vec2 texel = pixel_size / screen_size;

	float center_luma = luma(color);
	float right_luma = luma(texture(screen_texture, pixelated_uv + vec2(texel.x, 0.0)).rgb);
	float up_luma = luma(texture(screen_texture, pixelated_uv + vec2(0.0, texel.y)).rgb);
	float edge = smoothstep(0.08, 0.25, abs(center_luma - right_luma) + abs(center_luma - up_luma));

	// Apply warm tint and saturation before posterization for better blending
	color *= warm_tint * brightness;
	color = mix(vec3(luma(color)), color, saturation);

	// 4x4 Bayer Dithering for soft nostalgic retro feel
	int dx = int(mod(uv.x * screen_size.x / pixel_size, 4.0));
	int dy = int(mod(uv.y * screen_size.y / pixel_size, 4.0));
	float dither_matrix[16] = float[](
		0.0, 8.0, 2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0,
		15.0, 7.0, 13.0, 5.0
	);
	float dither_val = (dither_matrix[dx + dy * 4] / 16.0) - 0.5;
	color += dither_val * (2.0 / color_levels);

	// Posterize
	color = floor(color * color_levels) / color_levels;

	float scanline = sin(uv.y * screen_size.y * 3.14159);
	color *= 1.0 - (scanline_strength * (0.5 + 0.5 * scanline));

	float noise = random(pixelated_uv + TIME * 0.15) - 0.5;
	color += noise * noise_strength;
	color = mix(color, color * 0.68, edge * edge_strength);

	float vignette = smoothstep(0.85, 0.2, distance(uv, vec2(0.5)));
	color *= mix(1.0 - vignette_strength, 1.0, vignette);

	ALBEDO = clamp(color, vec3(0.0), vec3(1.0));
	ALPHA = 1.0;
}
