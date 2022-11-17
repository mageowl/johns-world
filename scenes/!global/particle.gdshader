shader_type canvas_item;

uniform float radius = 0.4;
uniform sampler2D colorGradient;
uniform bool useDonut = false;
uniform sampler2D donutCurve;

varying flat float donut;

void fragment() {
	float dist = length( UV - 0.5 );
	float a = 0.0;
	if (dist < radius / 2.0 && dist > donut * (radius / 2.0)) a = 1.0;
	COLOR = vec4( COLOR.rgb, COLOR.a * a );
}

void vertex() {
	vec4 sampleColor = texture( colorGradient, vec2(INSTANCE_CUSTOM.y, 0) );
	COLOR = sampleColor;
	if (useDonut) {
		donut = texture( donutCurve, vec2(INSTANCE_CUSTOM.y, 0) ).r;
	} else donut = 0.0;
}