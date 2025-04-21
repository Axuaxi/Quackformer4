shader_type canvas_item;

uniform float time;
uniform float wave_strength = 1.0;
uniform float wave_speed = 2.0;
uniform float wave_scale = 1.0;
uniform vec4 lava_color : source_color = vec4(1.0, 0.3, 0.0, 1.0);

void fragment() {
	vec2 uv = UV;
	uv.y += sin(uv.x * wave_scale + time * wave_speed) * wave_strength / 100.0;
	vec4 tex = texture(TEXTURE, uv);
	COLOR = tex;
}
