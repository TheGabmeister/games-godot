shader_type canvas_item;

uniform float flash_amount = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	tex.rgb = mix(tex.rgb, vec3(1.0), flash_amount);
	COLOR = tex;
}
