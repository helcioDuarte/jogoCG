shader_type canvas_item;

uniform float flash_alpha : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 previous_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    vec4 flash_color = vec4(1.0, 1.0, 1.0, flash_alpha);
    COLOR = mix(previous_color, flash_color, flash_alpha);
}