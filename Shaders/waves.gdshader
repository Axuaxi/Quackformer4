shader_type canvas_item;

uniform float wave_speed = 1.5;
uniform float wave_strength = 3.0;
uniform float wave_frequency = 12.0;
uniform float alpha : hint_range(0.0, 1.0) = 0.5; 

void fragment() {
    vec2 uv = UV;

    // Vertical heat shimmer (based on horizontal UV and time)
    float wave = sin(uv.x * wave_frequency + TIME * wave_speed) * wave_strength;

    // Apply vertical offset (scaled to screen pixels)
    uv.y += wave * SCREEN_PIXEL_SIZE.y;

    // Sample and apply opacity
    COLOR = texture(TEXTURE, uv);
    COLOR.a *= alpha;
}
