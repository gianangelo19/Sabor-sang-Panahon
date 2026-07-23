shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 4.0;
uniform float color_levels : hint_range(2.0, 64.0, 1.0) = 18.0;
uniform float toon_steps : hint_range(2.0, 8.0, 1.0) = 4.0;
uniform float toon_strength : hint_range(0.0, 1.0, 0.01) = 0.72;
uniform float scanline_strength : hint_range(0.0, 1.0, 0.01) = 0.03;
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform float warp_strength : hint_range(0.0, 0.08, 0.001) = 0.004;
uniform float noise_strength : hint_range(0.0, 0.2, 0.001) = 0.004;
uniform float edge_strength : hint_range(0.0, 1.0, 0.01) = 0.88;
uniform float edge_threshold : hint_range(0.01, 0.5, 0.001) = 0.075;
uniform float depth_edge_strength : hint_range(0.0, 1.0, 0.01) = 0.65;
uniform float depth_edge_threshold : hint_range(0.0001, 0.05, 0.0001) = 0.004;
uniform float outline_width : hint_range(1.0, 6.0, 0.5) = 2.0;
uniform float brightness : hint_range(0.5, 1.5, 0.01) = 1.12;
uniform float saturation : hint_range(0.0, 2.0, 0.01) = 1.18;
uniform vec3 ink_color = vec3(0.035, 0.024, 0.015);
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

	// Slight CRT-style bend
	vec2 centered_uv = uv * 2.0 - 1.0;
	float radius = dot(centered_uv, centered_uv);
	uv += centered_uv * radius * warp_strength;
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel_count = screen_size / pixel_size;
	vec2 pixelated_uv = (floor(uv * pixel_count) + 0.5) / pixel_count;
	vec3 color = texture(screen_texture, pixelated_uv).rgb;
	color = clamp(color, 0.0, 1.0);
	vec2 texel = (pixel_size * outline_width) / screen_size;

	// Edge detection (luma + depth)
	float center_luma = luma(color);
	float right_luma = luma(texture(screen_texture, pixelated_uv + vec2(texel.x, 0.0)).rgb);
	float left_luma = luma(texture(screen_texture, pixelated_uv - vec2(texel.x, 0.0)).rgb);
	float up_luma = luma(texture(screen_texture, pixelated_uv + vec2(0.0, texel.y)).rgb);
	float down_luma = luma(texture(screen_texture, pixelated_uv - vec2(0.0, texel.y)).rgb);
	float luma_edge_value = abs(center_luma - right_luma) + abs(center_luma - left_luma) + abs(center_luma - up_luma) + abs(center_luma - down_luma);
	float luma_edge = smoothstep(edge_threshold, edge_threshold * 3.0, luma_edge_value);

	float center_depth = texture(depth_texture, pixelated_uv).r;
	float right_depth = texture(depth_texture, pixelated_uv + vec2(texel.x, 0.0)).r;
	float left_depth = texture(depth_texture, pixelated_uv - vec2(texel.x, 0.0)).r;
	float up_depth = texture(depth_texture, pixelated_uv + vec2(0.0, texel.y)).r;
	float down_depth = texture(depth_texture, pixelated_uv - vec2(0.0, texel.y)).r;
	float depth_edge_value = abs(center_depth - right_depth) + abs(center_depth - left_depth) + abs(center_depth - up_depth) + abs(center_depth - down_depth);
	float depth_edge = smoothstep(depth_edge_threshold, depth_edge_threshold * 8.0, depth_edge_value);
	float edge = clamp(max(luma_edge, depth_edge * depth_edge_strength), 0.0, 1.0);

	// Original warm tint and color grading
	color *= warm_tint * brightness;
	color = mix(vec3(luma(color)), color, saturation);

	// 8x8 Bayer dithering (Shadowglass-style upgrade from 4x4)
	int dx = int(mod(uv.x * screen_size.x / pixel_size, 8.0));
	int dy = int(mod(uv.y * screen_size.y / pixel_size, 8.0));
	float dither_matrix[64] = float[](
		 0.0, 32.0,  8.0, 40.0,  2.0, 34.0, 10.0, 42.0,
		48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
		12.0, 44.0,  4.0, 36.0, 14.0, 46.0,  6.0, 38.0,
		60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
		 3.0, 35.0, 11.0, 43.0,  1.0, 33.0,  9.0, 41.0,
		51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
		15.0, 47.0,  7.0, 39.0, 13.0, 45.0,  5.0, 37.0,
		63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
	);
	float dither_val = (dither_matrix[dx + dy * 8] / 64.0) - 0.5;
	color += dither_val * (2.0 / color_levels);

	// Posterize
	color = clamp(floor(color * color_levels) / color_levels, 0.0, 1.0);

	// Toon shading
	float shaded_luma = luma(color);
	float banded_luma = (floor(shaded_luma * toon_steps) + 0.5) / toon_steps;
	vec3 hue = color / max(shaded_luma, 0.001);
	color = mix(color, hue * banded_luma, toon_strength);

	// Scanlines
	float scanline = sin(uv.y * screen_size.y * 3.14159);
	color *= 1.0 - (scanline_strength * (0.5 + 0.5 * scanline));

	// Film noise
	float noise = random(pixelated_uv + TIME * 0.15) - 0.5;
	color += noise * noise_strength;

	// Ink outlines
	color = mix(color, ink_color, edge * edge_strength);

	// Vignette
	float vignette = smoothstep(0.85, 0.2, distance(uv, vec2(0.5)));
	color *= mix(1.0 - vignette_strength, 1.0, vignette);
	
	ALBEDO = clamp(color, vec3(0.0), vec3(1.0));
	ALPHA = 1.0;
}
