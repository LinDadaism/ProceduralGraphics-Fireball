#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec2 u_Dimensions;
uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform int u_BgToggle;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

INCLUDE_TOOL_FUNCTIONS

#define WORLEY 1
float fbm(vec3 uv) {
    float sum = 0.0, noise = 0.0;
    float freq = 5.0;
    float amp = 0.5;
    int octaves = 6;//8;

    for(int i = 0; i < octaves; i++) {
#if WORLEY
        noise = worleyNoise3D(uv * freq) * amp;
#else
        noise = abs(perlinNoise3D(uv * freq)) * amp;
#endif
        sum += noise;
        freq *= 2.0;
        amp *= 0.5;
    }
    return sum;
}

const float F3 =  0.3333333;
const float G3 =  0.1666667;
float snoise(vec3 p) {

	vec3 s = floor(p + dot(p, vec3(F3)));
	vec3 x = p - s + dot(s, vec3(G3));
	 
	vec3 e = step(vec3(0.0), x - x.yzx);
	vec3 i1 = e*(1.0 - e.zxy);
	vec3 i2 = 1.0 - e.zxy*(1.0 - e);
	 	
	vec3 x1 = x - i1 + G3;
	vec3 x2 = x - i2 + 2.0*G3;
	vec3 x3 = x - 1.0 + 3.0*G3;
	 
	vec4 w, d;
	 
	w.x = dot(x, x);
	w.y = dot(x1, x1);
	w.z = dot(x2, x2);
	w.w = dot(x3, x3);
	 
	w = max(0.6 - w, 0.0);
	 
	d.x = dot(random3(s), x);
	d.y = dot(random3(s + i1), x1);
	d.z = dot(random3(s + i2), x2);
	d.w = dot(random3(s + 1.0), x3);
	 
	w *= w;
	w *= w;
	d *= w;
	 
	return dot(d, vec4(52.0));
}

float snoiseFractal(vec3 m) {
	return   0.5333333* snoise(m)
				+0.2666667* snoise(2.0*m)
				+0.1333333* snoise(4.0*m)
				+0.0666667* snoise(8.0*m);
}

const int compareDistance = 4; // >= 1

const int r2 = compareDistance * compareDistance;
const int steps = 6;
const vec3 colors[steps] = vec3[](vec3(0.133, 0.223, 0.345), vec3(0.270, 0.458, 0.690), vec3(0.458, 0.725, 0.745), vec3(0.815, 0.839, 0.709), vec3(0.976, 0.709, 0.674), vec3(0.933, 0.462, 0.454));

int getPixelStepi(vec2 pixel, vec2 dimensions, float t) {
    return min(max(int(((snoiseFractal(vec3(pixel / dimensions.y, t * 0.05)) + 0.5)) * float(steps)), 0), steps - 1);
}

float getPixelStepf(vec2 pixel, vec2 dimensions, float t) {
    return ((snoiseFractal(vec3(pixel / dimensions.y, t * 0.05)) + 0.5)) * float(steps);
}

void main()
{
    vec3 color2 = rgb(200.0, 107.0, 20.0);

    // Material base color (before shading)
    vec4 diffuseColor = vec4(color2, 1.0);
    if (u_BgToggle > 0) {
        float noise = fbm(fs_Pos.xyz) + 0.6;
        diffuseColor *= noise;

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb, diffuseColor.a);
    } else {
        float step = getPixelStepf(gl_FragCoord.xy, u_Dimensions.xy, u_Time);
        out_Col = vec4(colors[int(step)],1) * smoothstep(2.,4., abs(fract(step+.5)-.5) / fwidth(step) ) ;
    }
}
