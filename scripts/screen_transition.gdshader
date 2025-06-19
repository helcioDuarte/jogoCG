shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float swirl_strength : hint_range(0.0, 50.0) = 20.0;
uniform float zoom_strength : hint_range(0.0, 2.0) = 0.5;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 centered_uv = UV - vec2(0.5);
    float distance_from_center = length(centered_uv);
    float angle = atan(centered_uv.y, centered_uv.x);

    float swirl_effect = swirl_strength * progress * (1.0 - progress);
    angle += distance_from_center * swirl_effect;

    float zoom_effect = 1.0 + progress * zoom_strength;
    distance_from_center /= zoom_effect;

    vec2 distorted_uv = vec2(cos(angle), sin(angle)) * distance_from_center + vec2(0.5);
    vec4 screen_color = texture(SCREEN_TEXTURE, distorted_uv);

    float iris_alpha = 1.0 - smoothstep(1.0 - progress - 0.1, 1.0 - progress, distance_from_center * 1.5);
    
    COLOR = vec4(screen_color.rgb, iris_alpha);
}