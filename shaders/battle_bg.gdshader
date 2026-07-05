shader_type canvas_item;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	float t  = TIME;

	// Gradient: deep indigo top → dark violet bottom
	vec3 col = mix(vec3(0.03, 0.03, 0.15), vec3(0.07, 0.02, 0.22), uv.y);

	// Subtle CRT scanlines
	col -= sin(uv.y * 960.0) * 0.018;

	// Star layer 1 — large, slow drift
	{
		vec2 suv = uv + vec2(t * 0.003, 0.0);
		vec2 id  = floor(suv * 18.0);
		vec2 st  = fract(suv * 18.0) - 0.5;
		float h  = hash21(id);
		float br = hash21(id + vec2(1.3, 0.7));
		float tw = 0.5 + 0.5 * sin(t * (2.0 + br * 3.0) + br * 6.283);
		col += vec3(0.70, 0.80, 1.00) * smoothstep(0.08, 0.0, length(st)) * br * tw * step(h, 0.04);
	}
	// Star layer 2 — medium
	{
		vec2 suv = uv + vec2(t * 0.006, 0.0);
		vec2 id  = floor(suv * 30.0);
		vec2 st  = fract(suv * 30.0) - 0.5;
		float h  = hash21(id);
		float br = hash21(id + vec2(1.3, 0.7));
		float tw = 0.5 + 0.5 * sin(t * (2.0 + br * 3.0) + br * 6.283);
		col += vec3(0.75, 0.85, 1.00) * smoothstep(0.06, 0.0, length(st)) * br * tw * step(h, 0.04) * 0.75;
	}
	// Star layer 3 — dense, fine
	{
		vec2 suv = uv + vec2(t * 0.009, 0.0);
		vec2 id  = floor(suv * 50.0);
		vec2 st  = fract(suv * 50.0) - 0.5;
		float h  = hash21(id);
		float br = hash21(id + vec2(1.3, 0.7));
		float tw = 0.5 + 0.5 * sin(t * (2.0 + br * 3.0) + br * 6.283);
		col += vec3(0.80, 0.90, 1.00) * smoothstep(0.04, 0.0, length(st)) * br * tw * step(h, 0.035) * 0.50;
	}

	// Slow nebula drift (mid-screen band)
	float mist = sin(uv.x * 3.0 + uv.y * 2.0 + t * 0.12) * 0.5 + 0.5;
	mist *= smoothstep(0.05, 0.40, uv.y) * smoothstep(1.0, 0.60, uv.y);
	col += vec3(0.06, 0.01, 0.20) * mist * 0.40;

	COLOR = vec4(col, 1.0);
}
