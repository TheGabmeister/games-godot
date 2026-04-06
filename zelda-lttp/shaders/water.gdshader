shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 10.0) = 2.0;
uniform float period : hint_range(0.1, 5.0) = 1.5;
uniform vec4 color_a : source_color = vec4(0.1, 0.3, 0.7, 1.0);
uniform vec4 color_b : source_color = vec4(0.2, 0.5, 0.9, 1.0);

void fragment() {
	vec2 uv = UV;
	uv.x += sin(uv.y * 10.0 + TIME / period * TAU) * amplitude / 256.0;
	uv.y += cos(uv.x * 8.0 + TIME / period * TAU) * amplitude / 224.0;

	vec4 tex_color = texture(TEXTURE, uv);
	float blend = sin(TIME / period * TAU) * 0.5 + 0.5;
	vec4 water_tint = mix(color_a, color_b, blend);

	COLOR = tex_color * water_tint;
}
