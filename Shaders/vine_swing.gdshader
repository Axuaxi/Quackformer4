shader_type canvas_item;

uniform float time_offset = 0.0;
uniform float sway_speed = 2.0;
uniform float sway_strength = 5.0; // in pixels
uniform float sway_frequency = 10.0;

void fragment() {
    vec2 uv = UV;

    // Calculate sway based on vertical UV
    float sway = sin(uv.y * sway_frequency + TIME * sway_speed + time_offset) * sway_strength;

    // Convert sway to normalized texture space (SCREEN_PIXEL_SIZE.x is pixel width)
    uv.x += sway * SCREEN_PIXEL_SIZE.x;

    COLOR = texture(TEXTURE, uv);
}
