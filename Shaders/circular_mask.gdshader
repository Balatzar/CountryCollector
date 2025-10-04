shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.45;
uniform vec2 center = vec2(0.5, 0.5);
uniform float edge_softness : hint_range(0.0, 0.1) = 0.01;

void fragment() {
	// Correct for aspect ratio so the mask stays perfectly circular in pixels
	vec2 uv = UV;
	vec2 d = uv - center;
	float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x; // width / height
	d.x *= aspect;
	float dist = length(d);

	// Create circular mask with soft edge
	float mask = smoothstep(radius + edge_softness, radius - edge_softness, dist);

	// Apply mask to alpha channel
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= mask;
}

