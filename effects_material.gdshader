shader_type canvas_item;

uniform bool flash_enabled = false;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 clothing_end_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
const vec4 clothing_start_color = vec4(117.0/255.0, 33.0/255.0, 148.0/255.0, 1.0);

void fragment() {
	
	vec4 texture_color = texture(TEXTURE, UV);
	vec4 output_color = texture_color;
	if (output_color == clothing_start_color) {
		output_color = clothing_end_color;
	}
	if (flash_enabled) {
		output_color = vec4(flash_color.r, flash_color.b, flash_color.g, texture_color.a);
	}
	COLOR = output_color;
}
