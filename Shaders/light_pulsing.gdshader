shader_type canvas_item;

uniform float pulse_speed = 1.0;
uniform float pulse_intensity = 0.2;

void fragment() {
    float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_intensity;
    COLOR = texture(TEXTURE, UV) * pulse;
}
