shader_type canvas_item;

uniform bool flash_enabled = false;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
const float border_alpha = 199.0/255.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
const float primary_alpha = 200.0/255.0;
uniform vec4 primary_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
const float secondary_alpha = 201.0/255.0;
uniform vec4 secondary_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
const float hat_alpha = 202.0/255.0;
uniform vec4 hat_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha = 1.0;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec4 output_color = texture_color;

	if (flash_enabled) {
		output_color = vec4(flash_color.r, flash_color.b, flash_color.g, texture_color.a);
	} else if (output_color.a == border_alpha) {
		output_color = border_color;
	} else if (output_color.a == primary_alpha) {
		output_color = primary_color;
	} else if (output_color.a == secondary_alpha) {
		output_color = secondary_color;
	} else if (output_color.a == hat_alpha) {
		output_color = hat_color;
	}

	output_color.a = output_color.a * alpha;
	COLOR = output_color;
}
