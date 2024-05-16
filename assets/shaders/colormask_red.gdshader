shader_type canvas_item;
uniform vec3 new_color: source_color;
uniform bool active = true;
void fragment() {
    if (active) COLOR.rgb = COLOR.r * new_color + COLOR.g + COLOR.b;
}