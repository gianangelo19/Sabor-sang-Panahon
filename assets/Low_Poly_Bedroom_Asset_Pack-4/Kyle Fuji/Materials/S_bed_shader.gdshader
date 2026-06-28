shader_type spatial;

// This is more of a specialized shader specifically tied to the bed, but
// it would work for any 3 colored RGB map image. Red corresponds to the
// legs, green to the blankets, and blue to the sheets. Using those as a 
// map, we can change their individual colors, roughness, metallic, etc.
// I also added the ability to put in a wood texture for the bed frame.
uniform sampler2D rgb_texture_map;
uniform sampler2D normal_map : hint_normal;
uniform sampler2D ao_map;
uniform sampler2D wood_texture;
uniform bool wood_bed_frame;
uniform vec3 bed_frame_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 blanket_color : source_color = vec3(0.4, 0.4, 0.4);
uniform vec3 sheet_color : source_color = vec3(0.9, 0.9, 0.9);
uniform float bed_frame_roughness : hint_range(0.0, 1.0) = 0.5;
uniform float blanket_roughness : hint_range(0.0, 1.0) = 1.0;
uniform float sheet_roughness : hint_range(0.0, 1.0) = 1.0;
uniform float bed_frame_metallic : hint_range(0.0, 1.0) = 1;

void fragment() {
	vec4 packed_data = texture(rgb_texture_map, UV);
	vec4 normal_data = texture(normal_map, UV);
	vec4 ao_data = texture(ao_map, UV);
	vec4 wood_data = texture(wood_texture, UV);

	float bed_frame_map = step(0.2, packed_data.r);
	float blanket_map = step(0.2, packed_data.g);
	float sheet_map = step(0.2, packed_data.b);

	vec3 bed_frame_mapped_color = bed_frame_map * bed_frame_color;
	if (wood_bed_frame) {
		bed_frame_mapped_color = bed_frame_mapped_color * wood_data.rgb;
	}
	vec3 blanket_mapped_color = blanket_map * blanket_color;
	vec3 sheet_mapped_color = sheet_map * sheet_color;

	float bed_frame_mapped_roughness = bed_frame_map * bed_frame_roughness;
	float blanket_mapped_roughess = blanket_map * blanket_roughness;
	float sheet_mapped_roughness = sheet_map * sheet_roughness;

	float bed_frame_mapped_metallic = bed_frame_map * bed_frame_metallic;

	ALBEDO = bed_frame_mapped_color + blanket_mapped_color + sheet_mapped_color;
	METALLIC = bed_frame_mapped_metallic;
	ROUGHNESS = bed_frame_mapped_roughness + blanket_mapped_roughess + sheet_mapped_roughness;
	NORMAL_MAP = normal_data.rgb;
	AO = ao_data.r;
}
