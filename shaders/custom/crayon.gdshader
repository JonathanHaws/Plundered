// NOTE: Shader automatically converted from Godot Engine 4.6.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;
group_uniforms regular_shader_material; // Converted from regular shader to make use of triplanar mapping
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);
uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

group_uniforms custom_crayon_effects;
uniform sampler2D crayon_texture_a: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D crayon_texture_b: source_color, filter_linear_mipmap, repeat_enable;
uniform float crayon_amount : hint_range(0.0, 1.0) = 0.5; // 0 = no crayon, 1 = full effect
uniform float speed_crayon = 6.0;
uniform float jiggle_strength = 0.008;
float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898,78.233,45.164))) * 43758.5453); }

void vertex() {
	
	// Crayon EFFECT (Jiggle)
	float t = floor(TIME * speed_crayon);
	vec3 rnd = vec3(hash(VERTEX + t), hash(VERTEX + t + 1.3), hash(VERTEX + t + 2.7)) * 2.0 - 1.0;
	VERTEX += rnd * jiggle_strength;
	
	// Standard
	vec3 normal = NORMAL;
	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);
	// UV1 Triplanar: Enabled
	uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	// Standard
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	float metallic_tex = dot(texture(texture_metallic, UV), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, UV), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	
	// Crayon effect
	float step_t = floor(TIME * speed_crayon); // use the same integer step
	vec4 crayon_tex_a = triplanar_texture(crayon_texture_a, uv1_power_normal, uv1_triplanar_pos);
	vec4 crayon_tex_b = triplanar_texture(crayon_texture_b, uv1_power_normal, uv1_triplanar_pos);
	vec4 crayon_mix = mix(crayon_tex_a, crayon_tex_b, step_t - floor(step_t / 2.0) * 2.0); 
	ALBEDO *= mix(vec3(1.0), crayon_mix.rgb, crayon_amount);
	
}
