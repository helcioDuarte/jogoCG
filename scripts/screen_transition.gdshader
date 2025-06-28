shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 0.5) = 0.1;
uniform int samples : hint_range(1, 64) = 32;
uniform float white_tint_strength : hint_range(0.0, 1.0) = 0.7;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	float effective_progress = min(progress * 2.0, 1.0);
	vec2 direction = vec2(0.5) - UV;
	vec4 final_color = texture(SCREEN_TEXTURE, UV);
	float blur_strength = effective_progress * strength;

	if (blur_strength > 0.0) {
		final_color = vec4(0.0);
		for (int i = 0; i < samples; i++) {
			float offset = float(i) / float(samples - 1) * blur_strength;
			final_color += texture(SCREEN_TEXTURE, UV + direction * offset);
		}
		final_color /= float(samples);
	}

	if (effective_progress > 0.0) {
		float whiteness = pow(1.0 - effective_progress, 2.0) * white_tint_strength;
		final_color.rgb = mix(final_color.rgb, vec3(1.0), whiteness);
	}

	COLOR = final_color;
}