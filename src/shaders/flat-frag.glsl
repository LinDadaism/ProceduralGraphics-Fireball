#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;
uniform int u_BgToggle;

in vec2 fs_Pos;
out vec4 out_Col;

INCLUDE_TOOL_FUNCTIONS

/* 
 * Rotate an input point about some center by angle
 */
vec2 rotatePoint2d(vec2 uv, vec2 center, float angle)
{
    vec2 rotatedPoint = vec2(uv.x - center.x, uv.y - center.y);
    float newX = cos(angle) * rotatedPoint.x - sin(angle) * rotatedPoint.y;
    rotatedPoint.y = sin(angle) * rotatedPoint.x + cos(angle) * rotatedPoint.y;
    rotatedPoint.x = newX;
    return rotatedPoint;
}

vec4 circle(vec2 uv, vec2 center, float radius, vec3 color)
{
  // Get distance of point from center, get difference from given radius
	float d = length(center - uv) - radius;
	float t = clamp(d, 0.0, 1.0);
    
  // If point is smaller than radius, set color alpha to 1, otherwise 0
	return vec4(color, 1.0 - t);
}

float computeRadius(vec2 uv)
{
  float radius = 0.25 * u_Dimensions.y;
  
  // Centered uv
  vec2 uvCenter = (2.0f * uv - u_Dimensions.xy);
  
  vec2 movingUv = rotatePoint2d(uvCenter, vec2(0.0), u_Time);
  // Get pixel angle around the center
  float a = atan(movingUv.x,movingUv.y);
  
  return radius + radius * sin(a * u_Time) * abs(fract(a * 0.79)* 2.0-0.5);
}

#define WORLEY 0
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

void main() {
  if (u_BgToggle > 0) {
    // TODO: make these GUI adjustables
    float speed = 100.0;
    float dist = 100.0; 
    float zoom = 0.001;
    vec3 color = vec3(0.933, 0.169, 0.1);

    // a intensity from noise
    float a = max(0.0, 4.0 - distance(gl_FragCoord.xy, u_Dimensions.xy/2.0)/dist);
    
    vec2 sampleCoord = vec2(gl_FragCoord.x, gl_FragCoord.y - u_Time*speed); 
    float i = fbm(vec3(sampleCoord, 0.0) * zoom);
    a *= a; 
    a /= i*2.0; 

    out_Col = vec4(color * a, 1.0);
  } else {
    // test using my custom flower from lab 1
    vec2 uv = vec2(gl_FragCoord.xy);
    vec2 center = u_Dimensions.xy * 0.5;

    float radius = 2.0 * computeRadius(uv);

    // Background layer
    vec4 layer1 = vec4(rgb(255.0, 255.0, 210.0), 1);

    // Circle
    vec3 red = vec3(0.458, 0.725, 0.745);
    vec4 layer2 = circle(uv, center, radius * abs(cos(u_Time)) * 0.6, red);
      
    // layer3
    vec3 blue = vec3(0.270, 0.458, 0.690);
    vec4 layer3 = circle(uv, center, radius * 0.3, blue);

    out_Col = mix(layer1, layer2, layer2.a);
    out_Col = mix(out_Col, layer3, layer3.a);
  }
  
  // vec4(0.5 * (fs_Pos + vec2(1.0)), 0.5 * (sin(u_Time * 3.14159 * 0.01) + 1.0), 1.0);
}
