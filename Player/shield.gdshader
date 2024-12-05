shader_type canvas_item;

uniform vec4 color: source_color = vec4(1.0);
uniform float thickness: hint_range(0,1) = 0.1;


float circle(vec2 position, float radius, float feather)
{
	return smoothstep(radius, radius + feather, length(position - vec2(0.5)));
}


void fragment(){

  float outer_radius = 0.35;
  float inner_radius = outer_radius - thickness;

	float fade_effect = sin(TIME * 2.0) * 0.005;

	float outer = circle(vec2(UV.x, UV.y), outer_radius + fade_effect, 0.01);
	float inner = 1.0 - circle(vec2(UV.x, UV.y), inner_radius - fade_effect, 0.3);

	COLOR = color;
	COLOR.a -= outer + inner;
}
