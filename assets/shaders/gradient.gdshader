shader_type canvas_item;
uniform sampler2D gradient:hint_default_black;
void fragment() {
    COLOR *= texture(gradient,UV);
    // Called for every pixel the material is visible on.
}