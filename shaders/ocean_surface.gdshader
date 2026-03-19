shader_type spatial;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec2 mesh_size = vec2(0.0, 0.0);
uniform vec2 ocean_position = vec2(0.0, 0.0);

group_uniforms Color;
uniform float max_depth : hint_range(0.1, 50.0, 0.1) = 10.0; // Max depth to visualize, controls brightness
uniform float water_level : hint_range(-10.0, 10.0, 0.1) = 0.0; // Base height of the water surface
uniform vec3 color : source_color = vec3(0.0, 0.05, 0.1);
uniform float fade_start_depth : hint_range(0.0, 50.0, 0.1) = 0.5;
float get_linear_depth(sampler2D d_tex, vec2 uv, mat4 inv_proj) {
    float depth = texture(d_tex, uv).x;
    vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	    ndc.z = depth * 2.0 - 1.0;
	#endif
	    vec4 view = inv_proj * vec4(ndc, 1.0);
    return -view.z / view.w;
	}

group_uniforms Normals;
uniform sampler2D water_normal_texture;
uniform float scale_normal_1 = 0.04;
uniform float scale_normal_2 = 0.16; // second scale
uniform vec2 normal_texture_scroll_direction_1 = vec2(0.05, 0.02);
uniform vec2 normal_texture_scroll_direction_2 = vec2(-0.03, 0.04);
vec3 get_normal(vec2 uv, float time) {
	vec2 uv1 = (uv - (ocean_position / mesh_size)) * (scale_normal_1 * mesh_size.x) + normal_texture_scroll_direction_1 * time;
	vec2 uv2 = (uv - (ocean_position / mesh_size)) * (scale_normal_2 * mesh_size.x) + normal_texture_scroll_direction_2 * time;
	return normalize(
		(texture(water_normal_texture, uv1).xyz * 2.0 - 1.0) +
		(texture(water_normal_texture, uv2).xyz * 2.0 - 1.0)
	);
}

//group_uniforms Waves;
//float get_ocean_level_at(vec3 pos, float time) {
	//float amplitude = 1.0;       // wave height
	//float wavelength = 10.0;     
	//float speed = 2.0;           
	//float k = 6.28318 / wavelength;
	//return amplitude * sin(k * (pos.x + pos.z) - speed * time);
//}

void vertex() {
	//vec3 wave_pos = vec3(VERTEX.x - ocean_position.x, 0.0, VERTEX.z - ocean_position.y);
	//VERTEX.y += get_ocean_level_at(wave_pos, TIME);
}

void fragment() {

	float water_linear_depth = -VERTEX.z;
	float bg_linear_depth = get_linear_depth(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX);
	float thickness = max(0.0, bg_linear_depth - water_linear_depth);

	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	float fade_range = max(0.001, max_depth - fade_start_depth);
	float depth_ratio = clamp((thickness - fade_start_depth) / fade_range, 0.0, 1.0);

	ALBEDO = mix(screen_color, color, depth_ratio);
	NORMAL_MAP = get_normal(UV, TIME);
	ROUGHNESS = 0.2;
}
