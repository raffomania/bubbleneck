shader_type canvas_item;

uniform vec4 color : source_color;
uniform float threshold = 0.9;

void fragment() {
	    vec4 tex_color = texture(TEXTURE, UV);

      float sum = (tex_color.r + tex_color.g + tex_color.b) / 3.0;
      if (sum < threshold){
        COLOR= color;
      } else {
        COLOR= vec4(0.0, 0.0, 0.0, 0.0);
      }
}
