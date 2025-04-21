shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Black
uniform float outline_size = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (tex_color.a == 0.0) {
        // Check surrounding pixels for non-transparent neighbors
        float alpha = 0.0;
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                vec2 offset = vec2(float(x), float(y)) * outline_size / TEXTURE_PIXEL_SIZE;
                vec4 neighbor = texture(TEXTURE, UV + offset);
                alpha = max(alpha, neighbor.a);
            }
        }

        if (alpha > 0.0) {
            COLOR = outline_color;
        } else {
            COLOR = tex_color;
        }
    } else {
        COLOR = tex_color;
    }
}
