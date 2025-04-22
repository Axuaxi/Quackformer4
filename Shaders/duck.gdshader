shader_type canvas_item;

uniform float bob_speed = 2.0;
uniform float bob_amount = 0.01;
uniform bool is_idle = false;

void fragment() {
    vec2 uv_offset = vec2(0.0);
    if (is_idle) {
        uv_offset.y = sin(TIME * bob_speed) * bob_amount;
    }
    COLOR = texture(TEXTURE, UV + uv_offset);
}
