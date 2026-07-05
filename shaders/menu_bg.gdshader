shader_type canvas_item;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t  = TIME;

	// Deep blue-to-black gradient
	vec3 col = mix(vec3(0.02, 0.02, 0.12), vec3(0.01, 0.00, 0.07), uv.y);

	// Voronoi crystal lattice — mako energy
	vec2 scaled = uv * 5.0;
	vec2 vid    = floor(scaled);
	vec2 vst    = fract(scaled);
	float vmin  = 1.0;
	for (int vy = -1; vy <= 1; vy++) {
		for (int vx = -1; vx <= 1; vx++) {
			vec2 nb    = vec2(float(vx), float(vy));
			vec2 point = 0.5 + 0.45 * sin(t * 0.6 + 6.283 * hash22(vid + nb));
			vmin = min(vmin, length(nb + point - vst));
		}
	}
	float edge   = 1.0 - smoothstep(0.02, 0.10, vmin);
	float cshift = sin(t * 0.4 + uv.x * 3.0 + uv.y * 2.0) * 0.5 + 0.5;
	vec3  mako   = mix(vec3(0.00, 0.80, 0.50), vec3(0.10, 0.40, 1.00), cshift);
	col += mako * edge * 0.28;

	// Central pulse glow (title area)
	float pulse = 0.5 + 0.5 * sin(t * 1.5);
	col += vec3(0.04, 0.18, 0.75) * smoothstep(0.78, 0.0, distance(uv, vec2(0.5, 0.38))) * pulse * 0.22;

	// Stars — fade toward bottom
	{
		vec2 suv = uv + vec2(t * 0.002, 0.0);
		vec2 sid = floor(suv * 22.0);
		vec2 sst = fract(suv * 22.0) - 0.5;
		float h  = hash21(sid);
		float br = hash21(sid + vec2(2.1, 0.9));
		float tw = 0.4 + 0.6 * sin(t * 2.5 + br * 6.283);
		col += vec3(0.70, 0.85, 1.00) * smoothstep(0.08, 0.0, length(sst)) * br * tw * step(h, 0.05) * (1.0 - uv.y * 0.8);
	}

	COLOR = vec4(col, 1.0);
}
