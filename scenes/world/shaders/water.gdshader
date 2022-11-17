shader_type canvas_item;

uniform vec4 wave_top : source_color;

void fragment() {
	vec2 pixel_uv = UV / SCREEN_PIXEL_SIZE;
	float wave_cap = sin(( TIME * 100.0) * 0.01) * 10.0 + 10.0;
	
	if (pixel_uv.y < wave_cap) {
		COLOR = vec4(0);
	} else {
		if (pixel_uv.y <= wave_cap + 10.0) {
			COLOR = vec4(1); 
		} else {
			COLOR = vec4(0, 0.25, 0.75, 0.25);
		}
	}
}
