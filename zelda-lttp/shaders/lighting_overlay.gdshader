shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	float dist = distance(SCREEN_UV, vec2(0.5, 0.5));
	float vignette = smoothstep(0.4, 0.9, dist) * vignette_strength;
	color.rgb *= (1.0 - vignette);
	COLOR = color;
}
