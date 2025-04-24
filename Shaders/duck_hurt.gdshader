shader_type canvas_item;

uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 dark_red = vec3(0.7, 0.0, 0.0); // darker red
	vec3 flash_color = mix(tex_color.rgb, dark_red, flash_strength);
	COLOR = vec4(flash_color, tex_color.a);
}
