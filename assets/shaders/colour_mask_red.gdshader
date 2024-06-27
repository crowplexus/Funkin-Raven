shader_type canvas_item;
uniform vec3 colour: source_color;
uniform bool active = true;
void fragment() {
    if (active) COLOR.rgb = COLOR.r * colour + COLOR.g + COLOR.b;
}