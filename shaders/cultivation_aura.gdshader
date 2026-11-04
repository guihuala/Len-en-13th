shader_type canvas_item;
render_mode unshaded;

uniform int action_stage = 0;
uniform vec2 area_size = vec2(334.0, 300.0);
uniform vec3 tap_0 = vec3(0.5, 0.5, 2.0);
uniform vec3 tap_1 = vec3(0.5, 0.5, 2.0);
uniform vec3 tap_2 = vec3(0.5, 0.5, 2.0);
uniform vec3 tap_3 = vec3(0.5, 0.5, 2.0);
uniform vec4 action_tint : source_color = vec4(0.73, 0.87, 0.70, 1.0);
uniform float effect_time = 0.0;
uniform float boost : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Distances use the same unit in x/y, independent of the view's aspect ratio.
float stroke(float distance, float width) {
	return exp(-pow(distance / width, 2.0));
}

float leaf_shape(vec2 p, float angle, float length_scale) {
	float c = cos(angle);
	float s = sin(angle);
	vec2 q = mat2(vec2(c, -s), vec2(s, c)) * p / length_scale;
	float lens = max(length(q - vec2(0.0, 0.55)), length(q + vec2(0.0, 0.55)));
	return 1.0 - smoothstep(0.98, 1.06, lens);
}

vec2 tap_light(vec2 uv, vec3 tap) {
	if (tap.z >= 1.0) { return vec2(0.0); }
	float t = clamp(tap.z, 0.0, 1.0);
	vec2 p = (uv - tap.xy) * area_size / min(area_size.x, area_size.y);
	float ease = 1.0 - pow(1.0 - t, 2.0);
	float ink = 0.0;
	float light = 0.0;

	if (action_stage == 0) {
		// Water: two flattened ripples and an upward crown of droplets.
		float d = length(p * vec2(1.0, 2.0));
		float r = 0.035 + ease * 0.26;
		ink = stroke(d - r, 0.005 + t * 0.005) * 0.68;
		light = stroke(d - r, 0.018) * 0.24 + stroke(d - r * 0.68, 0.004) * 0.34;
		for (int i = 0; i < 8; i++) {
			float n = float(i);
			float a = -2.85 + n * 0.37;
			vec2 drop = vec2(cos(a), sin(a)) * (0.035 + ease * (0.14 + hash(vec2(n, tap.x)) * 0.10));
			drop.y += t * t * 0.24;
			vec2 q = (p - drop) * vec2(1.0, 0.65);
			light += exp(-dot(q, q) / 0.000065) * 0.95;
		}
	} else if (action_stage == 1) {
		// Fertilizer: warm grains descend and dissolve into the soil.
		for (int i = 0; i < 9; i++) {
			float n = float(i);
			float x = (hash(vec2(n, 1.0)) - 0.5) * 0.48;
			float start = -0.23 - hash(vec2(n, 4.0)) * 0.16;
			float y = min(0.02, start + ease * 0.48);
			vec2 q = (p - vec2(x, y)) * vec2(1.0, 0.65);
			float grain = exp(-dot(q, q) / 0.00014);
			ink += grain * 0.48;
			light += grain * 0.98;
			float soak = stroke(length((p - vec2(x, 0.02)) * vec2(1.0, 3.2)) - (0.012 + t * 0.045), 0.004);
			light += soak * smoothstep(0.15, 0.5, t) * 0.23;
		}
	} else if (action_stage == 2) {
		// Care: paired leaf buds unfold and drift up from the point of contact.
		for (int i = 0; i < 6; i++) {
			float n = float(i);
			float a = n * 1.0472 + 0.4;
			vec2 center = vec2(cos(a), sin(a)) * (0.035 + ease * 0.16) - vec2(0.0, t * 0.06);
			float leaf = leaf_shape(p - center, a + t * 0.55, 0.012 + sin(t * 3.14159) * 0.025);
			ink += leaf * 0.48;
			light += leaf * 0.44 + exp(-dot(p - center, p - center) / 0.000035) * 0.50;
		}
		light += exp(-dot(p, p) / 0.018) * 0.10;
	} else if (action_stage == 3) {
		// Root guidance uses the hand-painted atlas overlay.
		// Keep only the shared boost aura from this shader.
	} else if (action_stage == 4) {
		// Prune: a feathered crescent sweeps through, followed by falling cut leaves.
		vec2 q = p * vec2(0.85, 1.35);
		float angle = atan(q.y, q.x);
		float radius = 0.08 + ease * 0.20;
		float arc = stroke(length(q) - radius, 0.005) * smoothstep(-0.7, 0.2, sin(angle + t * 1.7));
		ink = arc * 0.36;
		light = arc * 0.67 + stroke(length(q) - radius, 0.018) * 0.16;
		for (int i = 0; i < 5; i++) {
			float n = float(i);
			vec2 center = vec2((n - 2.0) * (0.025 + ease * 0.05), -0.06 + t * t * 0.30 - sin(n) * 0.04);
			float leaf = leaf_shape(p - center, n + t * 2.8, 0.022);
			ink += leaf * 0.54;
			light += leaf * 0.30;
		}
	} else if (action_stage == 5) {
		// Direct: a soft sector of light sweeps across a set of three destinations.
		vec2 q = p * vec2(1.0, 1.3);
		float angle = atan(q.y, q.x);
		float scan_angle = -2.7 + ease * 3.5;
		float beam = exp(-pow(sin(angle - scan_angle) / 0.12, 2.0)) * step(0.0, cos(angle - scan_angle));
		light = beam * exp(-dot(q, q) / 0.05) * 0.24;
		ink = stroke(length(q) - (0.27 + ease * 0.08), 0.0045) * 0.48;
		light += stroke(length(q) - (0.27 + ease * 0.08), 0.012) * 0.26;
		for (int i = 0; i < 3; i++) {
			float a = -2.6 + float(i) * 1.15;
			vec2 center = vec2(cos(a), sin(a) / 1.3) * 0.32;
			float arrival = smoothstep(0.05 + float(i) * 0.17, 0.18 + float(i) * 0.17, t);
			light += (stroke(length(p - center) - 0.016, 0.004) * 0.50 + exp(-dot(p - center, p - center) / 0.00008) * 0.8) * arrival;
		}
	} else {
		// Coordinate: two crossing orbital waves with travelling points of light.
		float radius = 0.24 + ease * 0.17;
		for (int i = 0; i < 2; i++) {
			float tilt = float(i) * 1.05 - 0.45;
			float c = cos(tilt);
			float s = sin(tilt);
			vec2 q = mat2(vec2(c, -s), vec2(s, c)) * p;
			float d = length(q * vec2(1.0, 1.8));
			ink += stroke(d - radius, 0.004) * 0.35;
			light += stroke(d - radius, 0.013) * 0.38;
			float a = t * 4.0 + float(i) * 3.14159;
			vec2 orbit = vec2(cos(a), sin(a) / 1.8) * radius;
			vec2 center = mat2(vec2(c, s), vec2(-s, c)) * orbit;
			light += exp(-dot(p - center, p - center) / 0.00010) * 1.15;
		}
	}
	return vec2(ink, light) * smoothstep(0.0, 0.035, t) * pow(1.0 - t, 1.2);
}

void fragment() {
	vec2 clicks = tap_light(UV, tap_0) + tap_light(UV, tap_1) + tap_light(UV, tap_2) + tap_light(UV, tap_3);
	vec2 p = (UV - vec2(0.5, 0.55)) * area_size / min(area_size.x, area_size.y);
	float halo = exp(-pow((length(p * vec2(1.0, 0.85)) - 0.30) / 0.085, 2.0));
	float drift = 0.65 + 0.35 * sin(atan(p.y, p.x) * 3.0 - effect_time * 0.8);
	vec2 field = UV * vec2(9.0, 11.0) + vec2(0.0, effect_time * 0.26);
	vec2 cell = floor(field);
	vec2 center = vec2(hash(cell), hash(cell + 23.0));
	vec2 delta = fract(field) - center;
	float dust = exp(-dot(delta, delta) * 1100.0) * step(0.72, hash(cell + 7.0));
	float mask = smoothstep(0.0, 0.14, UV.x) * smoothstep(0.0, 0.14, 1.0 - UV.x) * smoothstep(0.0, 0.14, UV.y) * smoothstep(0.0, 0.14, 1.0 - UV.y);
	float accelerated = boost * (halo * drift * 0.065 + dust * 0.38) * mask;
	vec3 light_color = mix(action_tint.rgb, vec3(0.98, 0.89, 0.61), boost * 0.7);
	vec3 ink_color = action_tint.rgb * vec3(0.38, 0.50, 0.42);
	float total = clicks.x + clicks.y + accelerated;
	vec3 pigment = (ink_color * clicks.x + light_color * (clicks.y + accelerated)) / max(total, 0.0001);
	COLOR = vec4(pigment, min(total, 0.72) * strength);
}
