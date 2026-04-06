shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform float smoothness : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	float dist = distance(UV, center);
	float max_dist = distance(vec2(0.0, 0.0), vec2(0.5, 0.5));
	float radius = progress * max_dist * 1.5;
	float alpha = smoothstep(radius, radius + smoothness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
