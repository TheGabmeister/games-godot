shader_type canvas_item;

uniform float bloom_strength : hint_range(0.0, 1.0) = 0.3;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.7;
uniform vec3 color_shift = vec3(0.0, 0.0, 0.0);
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);

	// Simple bloom approximation: sample blurred neighbors
	vec2 pixel_size = vec2(1.0) / vec2(textureSize(screen_texture, 0));
	vec4 bloom = vec4(0.0);
	float bloom_samples = 0.0;
	for (float x = -2.0; x <= 2.0; x += 1.0) {
		for (float y = -2.0; y <= 2.0; y += 1.0) {
			vec4 s = texture(screen_texture, SCREEN_UV + vec2(x, y) * pixel_size * 3.0);
			float lum = dot(s.rgb, vec3(0.299, 0.587, 0.114));
			if (lum > bloom_threshold) {
				bloom += s;
				bloom_samples += 1.0;
			}
		}
	}
	if (bloom_samples > 0.0) {
		bloom /= bloom_samples;
	}
	color.rgb += bloom.rgb * bloom_strength;

	// Color grading
	color.rgb += color_shift;

	// Saturation
	float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(grey), color.rgb, saturation);

	// Brightness and contrast
	color.rgb = ((color.rgb - 0.5) * contrast + 0.5) * brightness;

	COLOR = color;
}
