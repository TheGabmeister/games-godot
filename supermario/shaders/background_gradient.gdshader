shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.35, 0.65, 0.95, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.20, 0.45, 0.85, 1.0);

void fragment() {
	COLOR = mix(top_color, bottom_color, UV.y);
}
