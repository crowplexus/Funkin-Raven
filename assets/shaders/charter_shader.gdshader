shader_type canvas_item;

uniform float capY;
uniform float spacing;
uniform float offset;
uniform float lineThickness;
uniform float curLine = 0;

float float_or(float a, float b) { return min(a + b, 1.0); }

void fragment() {
	float fragY = SCREEN_UV.y * 720.0;
	float lineMult = 1.0 - clamp(mod(curLine + floor((fragY - capY - offset) / spacing) + 1.0, 4), 0.0, 1.0);
	float colorMult = step(mod(fragY - capY - offset, spacing) - lineThickness * 0.5, lineThickness * 0.5);
	colorMult *= float_or(step(mod(SCREEN_UV.x * 1280.0, 20.0), 10.0), lineMult);
	COLOR *= 1.0 + colorMult;//(colorMult * (float_or(float_if_lt(mod(FRAGCOORD.x, 20.0), 10.0), float(1 - lineMult))));
}