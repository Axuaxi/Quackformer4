shader_type canvas_item;

uniform float blink_strength : hint_range(0.0, 1.0);
uniform float time_passed;

void fragment() {
    COLOR = texture(TEXTURE, UV);
    
    float blink = step(0.5, abs(sin(time_passed * 30.0)) * blink_strength);
    COLOR.a *= blink;
}
