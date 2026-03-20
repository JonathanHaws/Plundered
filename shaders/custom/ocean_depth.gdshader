shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled;
uniform vec3 color : source_color = vec3(0.0, 0.05, 0.1);
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

uniform float thickness_fade_distance = 5.0;

// Set quad geometry instance 3d settings to extra cull margin max. And 2*2 size

float get_linear_depth(sampler2D d_tex, vec2 uv, mat4 inv_proj) {
    float depth = texture(d_tex, uv).x;
    vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	    ndc.z = depth * 2.0 - 1.0;
	#endif
	    vec4 view = inv_proj * vec4(ndc, 1.0);
    return -view.z / view.w;
	}

//vec3 depth_to_world_position(sampler2D depth_texture, vec2 uv, mat4 inverse_projection_matrix, mat4 inverse_view_matrix) {
    //float depth = texture(depth_texture, uv).x;
    //vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
    //#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
        //ndc.z = depth * 2.0 - 1.0;
    //#endif
//
    //vec4 view_pos = inverse_projection_matrix * vec4(ndc, 1.0);
    //view_pos.xyz /= view_pos.w;
//
    //vec3 world_pos = (inverse_view_matrix * view_pos).xyz;
    //return world_pos;
//}

void vertex() {
	 POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float surface_level = 0.0;
	
	vec3 pixel_world_position = (INV_VIEW_MATRIX * vec4(UV * 2.0 - 1.0, -1.0, 1.0)).xyz;
	if (pixel_world_position.y > surface_level) discard; // Verifying this pixel is underwater
	
	float depth = get_linear_depth(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX) ;
	
	// TODO MAKE WATER THINNER TOWARDS THE SURFACE (Painful math though giving up for now)
	//vec3 depth_world_position = depth_to_world_position(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	//if (depth_world_position.y > surface_level) {
		//ALBEDO = vec3(1.0, 0.0, 0.0); // red
		////
		////float middle_percentage = (surface_level - pixel_world_position.y) / (depth_world_position.y - pixel_world_position.y);
		////vec3 surface_intercept_world_position = mix(pixel_world_position, depth_world_position, middle_percentage);
		////float distance_above_surface = length(depth_world_position - surface_intercept_world_position);
		////depth -= distance_above_surface; // subtract the part above the surface
	//}

	float fog = 1.0 - exp(-depth * 0.08);
	ALBEDO = mix(texture(SCREEN_TEXTURE, SCREEN_UV).rgb, color, fog);


}