shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float pixel_size : hint_range(1.0, 32.0, 1.0) = 3.0;
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

	// Slight CRT-style bend. Keep this subtle so UI and aiming still feel good.
	vec2 centered_uv = uv * 2.0 - 1.0;
	float radius = dot(centered_uv, centered_uv);
	uv += centered_uv * radius * warp_strength;
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel_count = screen_size / pixel_size;
	vec2 pixelated_uv = (floor(uv * pixel_count) + 0.5) / pixel_count;
	vec3 color = texture(screen_texture, pixelated_uv).rgb;
	vec2 texel = (pixel_size * outline_width) / screen_size;

	float center_luma = luma(color);
	float right_luma = luma(texture(screen_texture, pixelated_uv + vec2(texel.x, 0.0)).rgb);
	float up_luma = luma(texture(screen_texture, pixelated_uv + vec2(0.0, texel.y)).rgb);
	float left_luma = luma(texture(screen_texture, pixelated_uv - vec2(texel.x, 0.0)).rgb);
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

	// Limited palette look.
	color = floor(color * color_levels) / color_levels;
	color *= warm_tint * brightness;
	color = mix(vec3(luma(color)), color, saturation);

	float shaded_luma = luma(color);
	float banded_luma = (floor(shaded_luma * toon_steps) + 0.5) / toon_steps;
	vec3 hue = color / max(shaded_luma, 0.001);
	color = mix(color, hue * banded_luma, toon_strength);

	// Soft horizontal scanlines, kept gentle so the room feels nostalgic instead of harsh.
	float scanline = sin(uv.y * screen_size.y * 3.14159);
	color *= 1.0 - (scanline_strength * (0.5 + 0.5 * scanline));

	// Tiny film/noise shimmer.
	float noise = random(pixelated_uv + TIME * 0.15) - 0.5;
	color += noise * noise_strength;

	color = mix(color, ink_color, edge * edge_strength);

	// A light vignette frames the scene without making the apartment feel scary.
	float vignette = smoothstep(0.85, 0.2, distance(uv, vec2(0.5)));
	color *= mix(1.0 - vignette_strength, 1.0, vignette);
	
	ALBEDO = clamp(color, vec3(0.0), vec3(1.0));
	ALPHA = 1.0;
}
