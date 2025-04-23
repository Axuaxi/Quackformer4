shader_type canvas_item;

uniform float blink_strength : hint_range(0.0, 1.0) = 0.0;
uniform float time_passed = 0.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    float blink = abs(sin(time_passed * 30.0)) * blink_strength;

    // Smooth pulse between 1.0 and 0.5 alpha
    float alpha_multiplier = mix(1.0, 0.5, blink);

    COLOR = tex_color;
    COLOR.a *= alpha_multiplier;
}
