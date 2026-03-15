shader_type spatial;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec2 mesh_size = vec2(0.0, 0.0);
uniform vec2 ocean_position = vec2(0.0, 0.0);

group_uniforms Color;
uniform float max_depth : hint_range(0.1, 50.0, 0.1) = 10.0; // Max depth to visualize, controls brightness
uniform float water_level : hint_range(-10.0, 10.0, 0.1) = 0.0; // Base height of the water surface
uniform vec3 underwater_fog_color : source_color = vec3(0.0, 0.05, 0.1);
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
uniform float scale_normal_1 = 30.0;
uniform float scale_normal_2 = 5.0; // second scale
uniform vec2 normal_texture_scroll_direction_1 = vec2(0.05, 0.02);
uniform vec2 normal_texture_scroll_direction_2 = vec2(-0.03, 0.04);

//group_uniforms Vertex;

// Wave parameters
//uniform float sea_height : hint_range(0.0, 5.0) = 1.3;
//uniform float sea_choppy : hint_range(0.0, 10.0) = 4.0;
//uniform float sea_speed : hint_range(0.0, 5.0) = 1.5;
//uniform float sea_freq : hint_range(0.0, 0.5) = 0.08;
//uniform int ITER_GEOMETRY = 3; // Iterations
//uniform int ITER_FRAGMENT = 5;
//const mat2 octave_m = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));
//
//float hash12(vec2 p) {
    //uvec2 q = uvec2(ivec2(p)) * uvec2(1597334677u, 3812015801u);
    //uint n = (q.x ^ q.y) * 1597334677u;
    //return float(n) * (1.0 / 4294967295.0);
	//}
//float noise(in vec2 p) {
    //vec2 i = floor(p);
    //vec2 f = fract(p);
    //vec2 u = f * f * (3.0 - 2.0 * f);
    //return -1.0 + 2.0 * mix(mix(hash12(i + vec2(0.0, 0.0)), hash12(i + vec2(1.0, 0.0)), u.x),
                            //mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
	//}
//float sea_octave(vec2 uv, float choppy) {
    //uv += noise(uv);
    //vec2 wv = 1.0 - abs(sin(uv));
    //vec2 swv = abs(cos(uv));
    //wv = mix(wv, swv, wv);
    //return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy);
	//}
//float map(vec3 p, float time) {
    //float freq = sea_freq;
    //float amp = sea_height;
    //float choppy = sea_choppy;
    //vec2 uv = p.xz;
    //uv.x *= 0.75;
    //float h = 0.0;
    //for (int i = 0; i < ITER_GEOMETRY; i++) {
        //float d = sea_octave((uv + time * sea_speed) * freq, choppy);
        //d += sea_octave((uv - time * sea_speed) * freq, choppy);
        //h += d * amp;
        //uv *= octave_m;
        //freq *= 1.9;
        //amp *= 0.22;
        //choppy = mix(choppy, 1.0, 0.2);
    //}
    //return p.y - h;
	//}
//float map_detailed(vec3 p, float time) {
    //float freq = sea_freq;
    //float amp = sea_height;
    //float choppy = sea_choppy;
    //vec2 uv = p.xz;
    //uv.x *= 0.75;
    //float h = 0.0;
    //for (int i = 0; i < ITER_FRAGMENT; i++) {
        //float d = sea_octave((uv + time * sea_speed) * freq, choppy);
        //d += sea_octave((uv - time * sea_speed) * freq, choppy);
        //h += d * amp;
        //uv *= octave_m;
        //freq *= 1.9;
        //amp *= 0.22;
        //choppy = mix(choppy, 1.0, 0.2);
    //}
    //return p.y - h;
	//}
//vec3 get_normal_detailed(vec3 p, float eps, float time) {
    //vec3 n;
    //n.y = map_detailed(p, time);
    //n.x = map_detailed(vec3(p.x + eps, p.y, p.z), time) - n.y;
    //n.z = map_detailed(vec3(p.x, p.y, p.z + eps), time) - n.y;
    //n.y = eps;
    //return normalize(n);
	//}
//
//
//
//varying vec3 world_vert;
//varying float wave_height;
//varying vec3 vertex_normal_world;

void vertex() {
    //vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    //wave_height = -map(world_pos, TIME);
    //VERTEX.y = wave_height;
    //world_vert = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    //float vertex_eps = 0.1;
    //float h_center = wave_height;
    //float h_x = -map(world_pos + vec3(vertex_eps, 0.0, 0.0), TIME);
    //float h_z = -map(world_pos + vec3(0.0, 0.0, vertex_eps), TIME);
    //vec3 n_geom = normalize(vec3(h_center - h_x, vertex_eps, h_center - h_z));
    //vertex_normal_world = n_geom;
}

void fragment() {

	float water_linear_depth = -VERTEX.z;
	float bg_linear_depth = get_linear_depth(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX);
	float thickness = max(0.0, bg_linear_depth - water_linear_depth);

	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	float fade_range = max(0.001, max_depth - fade_start_depth);
	float depth_ratio = clamp((thickness - fade_start_depth) / fade_range, 0.0, 1.0);

	ALBEDO = mix(screen_color, underwater_fog_color, depth_ratio);
	
	
	vec2 uv1 = (UV - (ocean_position / mesh_size)) * scale_normal_1 + normal_texture_scroll_direction_1 * TIME;
	vec2 uv2 = (UV - (ocean_position / mesh_size)) * scale_normal_2 + normal_texture_scroll_direction_2 * TIME;

	vec3 combined_normal = normalize(
	    (texture(water_normal_texture, uv1).xyz * 2.0 - 1.0) +
	    (texture(water_normal_texture, uv2).xyz * 2.0 - 1.0)
	);
	NORMAL = (VIEW_MATRIX * vec4(combined_normal, 0.0)).xyz;
}
