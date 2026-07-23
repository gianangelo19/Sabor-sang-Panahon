shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;

// Full-screen CRT post-process. The defaults aim for a warm consumer television
// rather than a sharp LCD/pixel-art filter.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

group_uniforms tube_shape;
uniform float curvature : hint_range(0.0, 0.2, 0.001) = 0.065;
uniform float overscan : hint_range(1.0, 1.15, 0.001) = 1.028;
uniform float corner_radius : hint_range(0.0, 0.25, 0.001) = 0.085;
uniform float corner_softness : hint_range(0.001, 0.05, 0.001) = 0.012;
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.32;

group_uniforms phosphor;
uniform float scanline_strength : hint_range(0.0, 1.0, 0.01) = 0.21;
uniform float scanline_count : hint_range(120.0, 720.0, 1.0) = 340.0;
uniform float mask_strength : hint_range(0.0, 1.0, 0.01) = 0.14;
uniform float mask_pixel_size : hint_range(1.0, 6.0, 1.0) = 2.0;
uniform float chromatic_aberration : hint_range(0.0, 0.01, 0.0001) = 0.0016;
uniform float glow_strength : hint_range(0.0, 1.0, 0.01) = 0.16;
uniform float glow_threshold : hint_range(0.0, 1.0, 0.01) = 0.55;

group_uniforms analog_signal;
uniform float noise_strength : hint_range(0.0, 0.15, 0.001) = 0.012;
uniform float flicker_strength : hint_range(0.0, 0.1, 0.001) = 0.008;
uniform float rolling_bar_strength : hint_range(0.0, 0.15, 0.001) = 0.015;
uniform float rolling_bar_speed : hint_range(-2.0, 2.0, 0.01) = 0.18;
uniform float horizontal_jitter : hint_range(0.0, 0.003, 0.0001) = 0.0002;

group_uniforms color_grade;
uniform float brightness : hint_range(0.5, 1.5, 0.01) = 1.17;
uniform float contrast : hint_range(0.5, 1.5, 0.01) = 1.05;
uniform float saturation : hint_range(0.0, 2.0, 0.01) = 1.06;
uniform float vibrance : hint_range(0.0, 1.0, 0.01) = 0.22;
uniform float shadow_lift : hint_range(0.0, 0.2, 0.005) = 0.04;
uniform vec3 warm_tint = vec3(1.06, 1.015, 0.935);

float random(vec2 value) {
	return fract(sin(dot(value, vec2(12.9898, 78.233))) * 43758.5453);
}

float luma(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

vec2 curve_screen(vec2 uv) {
	vec2 centered = (uv * 2.0 - 1.0) / overscan;
	vec2 squared = centered * centered;
	centered *= vec2(
		1.0 + squared.y * curvature,
		1.0 + squared.x * curvature
	);
	return centered * 0.5 + 0.5;
}

float rounded_tube_mask(vec2 uv) {
	vec2 centered = abs(uv * 2.0 - 1.0);
	vec2 distance_to_box = centered - (vec2(1.0) - corner_radius);
	float signed_distance = (
		length(max(distance_to_box, vec2(0.0)))
		+ min(max(distance_to_box.x, distance_to_box.y), 0.0)
		- corner_radius
	);
	return 1.0 - smoothstep(-corner_softness, corner_softness, signed_distance);
}

vec3 sample_crt(vec2 uv, vec2 chroma_offset) {
	return vec3(
		texture(screen_texture, uv + chroma_offset).r,
		texture(screen_texture, uv).g,
		texture(screen_texture, uv - chroma_offset).b
	);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 texel = 1.0 / screen_size;
	vec2 curved_uv = curve_screen(SCREEN_UV);
	vec2 centered = curved_uv * 2.0 - 1.0;

	// Slight per-line instability keeps the signal analog without making the
	// picture distracting or difficult to read.
	float jitter_line = floor(curved_uv.y * scanline_count);
	float jitter_time = floor(TIME * 30.0);
	float jitter = random(vec2(jitter_line, jitter_time)) - 0.5;
	curved_uv.x += jitter * horizontal_jitter;

	vec2 chroma_offset = vec2(centered.x, centered.y * 0.35) * chromatic_aberration;
	vec3 color = sample_crt(curved_uv, chroma_offset);

	// A small bright-pass blur imitates light bleeding between nearby phosphors.
	vec3 blur = (
		texture(screen_texture, curved_uv + vec2(texel.x * 2.0, 0.0)).rgb
		+ texture(screen_texture, curved_uv - vec2(texel.x * 2.0, 0.0)).rgb
		+ texture(screen_texture, curved_uv + vec2(0.0, texel.y * 2.0)).rgb
		+ texture(screen_texture, curved_uv - vec2(0.0, texel.y * 2.0)).rgb
	) * 0.25;
	vec3 glow = max(blur - vec3(glow_threshold), vec3(0.0));
	color += glow * glow_strength;

	// Consumer CRT color response: gently warm, mildly saturated, with softer
	// blacks than the former posterized/toon treatment.
	color *= warm_tint * brightness;
	color = (color - vec3(0.5)) * contrast + vec3(0.5);
	color = mix(vec3(luma(color)), color, saturation);
	float color_range = max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b));
	float adaptive_vibrance = vibrance * (1.0 - clamp(color_range, 0.0, 1.0));
	color = mix(vec3(luma(color)), color, 1.0 + adaptive_vibrance);
	float dark_area = 1.0 - smoothstep(0.0, 0.45, luma(color));
	color += vec3(shadow_lift * dark_area);

	// Horizontal electron-beam scanlines.
	float scan_wave = 0.5 + 0.5 * cos(curved_uv.y * scanline_count * TAU);
	color *= 1.0 - scanline_strength * scan_wave;

	// RGB aperture-grille pattern, deliberately subtle so text remains legible.
	float mask_index = mod(floor(curved_uv.x * screen_size.x / mask_pixel_size), 3.0);
	vec3 phosphor_mask = vec3(0.72);
	if (mask_index < 1.0) {
		phosphor_mask.r = 1.0;
	} else if (mask_index < 2.0) {
		phosphor_mask.g = 1.0;
	} else {
		phosphor_mask.b = 1.0;
	}
	color *= mix(vec3(1.0), phosphor_mask, mask_strength);

	// Low-level RF noise, mains flicker, and a slowly traveling brightness band.
	float noise = random(SCREEN_UV * screen_size + vec2(jitter_time, -jitter_time)) - 0.5;
	color += noise * noise_strength;
	color *= 1.0 + sin(TIME * 60.0) * flicker_strength;
	float rolling_bar = 0.5 + 0.5 * sin((curved_uv.y - TIME * rolling_bar_speed) * TAU);
	color *= 1.0 - rolling_bar_strength * rolling_bar;

	// Darken toward the curved glass edge and cut the corners to the tube shape.
	float vignette = clamp(1.0 - dot(centered * vec2(0.72, 0.62), centered * vec2(0.72, 0.62)), 0.0, 1.0);
	vignette = mix(1.0, vignette, vignette_strength);
	float tube_mask = rounded_tube_mask(curved_uv);

	ALBEDO = clamp(color * vignette * tube_mask, vec3(0.0), vec3(1.0));
	ALPHA = 1.0;
}
