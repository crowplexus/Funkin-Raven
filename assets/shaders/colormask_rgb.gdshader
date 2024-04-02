shader_type canvas_item;
uniform vec3 red_mask :source_color;
uniform vec3 green_mask :source_color;
uniform vec3 blue_mask :source_color;
uniform bool active = true;
void fragment() {
    if (active) COLOR.rgb = COLOR.r * red_mask + COLOR.g * green_mask + COLOR.b * blue_mask;
}
