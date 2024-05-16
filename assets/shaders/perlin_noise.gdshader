shader_type canvas_item;
render_mode blend_mix;
// RotateUV
#include "res://addons/shaderV/uv/rotate.gdshaderinc"
// PerlinNoise2D
#include "res://addons/shaderV/rgba/noise/perlin2d.gdshaderinc"
void fragment() {
// Input:3
	vec2 n_out3p0 = SCREEN_UV;
	float n_out6p0;
// SinTIME:6
	float n_in6p0 = 0.25000;
	float n_in6p1 = 2.00000; {
		n_out6p0 = n_in6p1 * sin(n_in6p0 * TIME);
	}
	vec3 n_out7p0;
// RotateUV:7
	vec3 n_in7p2 = vec3(0.50000, 0.50000, 0.00000); {
		n_out7p0 = _rotateUV(vec3(n_out3p0, 0.0), n_in7p2.xy, n_out6p0);
	}
	float n_out10p0;
// ScaledTIME:10
	float n_in10p0 = 0.10000; {
		n_out10p0 = n_in10p0 * TIME;
	}
// VectorCompose:9
	float n_in9p1 = 0.00000;
	float n_in9p2 = 0.00000;
	vec3 n_out9p0 = vec3(n_out10p0, n_in9p1, n_in9p2);
	float n_out8p0;
// PerlinNoise2D:8
	float n_in8p2 = 5.00000;
	vec3 n_in8p3 = vec3(0.00000, 0.00000, 0.00000); {
		n_out8p0 = _perlin2dNoiseFunc((n_out7p0.xy+n_out9p0.xy)*n_in8p2, n_in8p3.xy);
	}
// Output:0
	COLOR.a = n_out8p0;
}