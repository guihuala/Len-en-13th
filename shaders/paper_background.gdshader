shader_type canvas_item;
render_mode unshaded;

uniform float motion_strength : hint_range(0.0, 1.0) = 1.0;
uniform float grain_strength : hint_range(0.0, 0.04) = 0.012;
uniform float light_strength : hint_range(0.0, 0.08) = 0.022;
uniform float incident_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 stage_tint : source_color = vec4(1.0);
uniform float exposure : hint_range(0.0, 2.0) = 1.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 cell = floor(UV * vec2(780.0, 1688.0));
	float grain = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	float t = TIME * 0.09 * motion_strength;
	float light = sin(UV.x * 4.0 + UV.y * 2.4 + t) * light_strength;
	vec3 paper = base.rgb * stage_tint.rgb * exposure + vec3(grain * grain_strength + light);
	paper = mix(paper, paper * vec3(0.96, 1.012, 0.95), incident_strength * 0.45);
	COLOR = vec4(clamp(paper, vec3(0.0), vec3(1.0)), base.a) * vertex_tint;
}
