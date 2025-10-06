shader_type canvas_item;

// Mask parameters
uniform float radius : hint_range(0.0, 1.0) = 0.48; // radius in UV space (pixel-correct)
uniform vec2 center = vec2(0.5, 0.5);
uniform float edge_softness : hint_range(0.0, 0.1) = 0.01;

// Spherical (fisheye-like) distortion strength. 0 = planar, 1 = full sphere mapping
uniform float distortion : hint_range(0.0, 1.0) = 0.85;

// Visual polish
uniform float rim_darkening : hint_range(0.0, 1.0) = 0;
uniform float rim_softness : hint_range(0.0, 0.5) = 0.1;

// Provide explicit aspect ratio (width / height)
uniform float tex_aspect = 1;

vec2 apply_spherical_distortion(vec2 uv) {
	// Normalize around center and scale X by aspect, so a unit circle is round in pixels
	vec2 p = vec2((uv.x - center.x) * tex_aspect, (uv.y - center.y)) / max(radius, 1e-6);
	float d = length(p);

	// If outside the circle of influence, no warp
	if (d >= 1.0) {
		return uv;
	}

	// Spherical mapping inspired by the Godot 3 screen-space example (adapted to UV sampling)
	float k = max(distortion, 1e-4);
	float z = sqrt(k + d * d * -k); // sqrt(k * (1 - d^2)) when k in [0,1]
	float r = atan(d, z) / 3.1415926535; // [0..0.5]
	float phi = atan(p.y, p.x);

	// Map back to UV space, undoing aspect scaling and reapplying radius
	vec2 q = vec2(r * cos(phi) / tex_aspect, r * sin(phi));
	return center + q * radius;
}

void fragment() {
	// Distort sampling coordinates using spherical model
	vec2 sample_uv = apply_spherical_distortion(UV);
	COLOR = texture(TEXTURE, sample_uv);

	// Compute distance in pixel-correct space for mask and rim
	vec2 dpx = UV - center;
	dpx.x *= tex_aspect;
	float dist_px = length(dpx);

	// Circular alpha mask
	float mask = smoothstep(radius + edge_softness, radius - edge_softness, dist_px);

	// Rim darkening near the edge to emphasize globe curvature
	float rim = smoothstep(radius - rim_softness, radius, dist_px);
	COLOR.rgb *= mix(1.0, 1.0 - rim_darkening, rim);
	COLOR.a *= mask;
}
