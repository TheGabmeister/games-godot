shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);

	// Purple hue shift
	vec3 purple_shift = vec3(0.05, -0.05, 0.1) * intensity;
	color.rgb += purple_shift;

	// Desaturate by 20%
	float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(color.rgb, vec3(grey), 0.2 * intensity);

	// Darken midtones
	color.rgb *= mix(1.0, 0.85, intensity);

	COLOR = color;
}
