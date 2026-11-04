shader_type canvas_item;
render_mode unshaded;
uniform vec2 area_size = vec2(120.0, 48.0);
uniform vec2 origin = vec2(0.5);
uniform float progress = 1.0;
void fragment() {
	vec2 p = (UV - origin) * area_size / max(area_size.x, area_size.y);
	float spread = 0.014 + progress * 0.3;
	float bloom = exp(-dot(p, p) / spread);
	float edge = smoothstep(0.0, 0.10, UV.x) * smoothstep(0.0, 0.10, 1.0 - UV.x) * smoothstep(0.0, 0.16, UV.y) * smoothstep(0.0, 0.16, 1.0 - UV.y);
	COLOR = vec4(0.98, 0.94, 0.75, bloom * edge * pow(1.0 - progress, 2.0) * 0.18);
}
