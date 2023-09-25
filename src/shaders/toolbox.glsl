/*
 * Make a vec3 color from rgb values [0, 255]
 */
vec3 rgb(float r, float g, float b)
{
	return vec3(r / 255.0, g / 255.0, b / 255.0);
}

/***************************************************************
 * FBM, Worley, Perlin noise functions from CIS5600
 ***************************************************************
*/
// noise basis function
float random1(vec3 p) {
    return fract(sin((dot(p, vec3(127.1,
                                  311.7,
                                  191.999)))) *         
                 43758.5453);
}

vec2 random2(vec2 p)
{
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                 dot(p, vec2(269.5,183.3))))
                 * 43758.5453);
}

vec3 random3(vec3 p)
{
    return fract(sin(vec3((dot(p, vec3(127.1f, 311.7f, 191.999f))))) * 43758.5453f);
}

float worleyNoise(vec2 uv, out vec2 cellPt)
{
    vec2 uvInt = floor(uv);
    vec2 uvFract = fract(uv);
    float minDist = 1.0; // Minimum distance initialized to max.
    for(int y = -1; y <= 1; ++y) {
        for(int x = -1; x <= 1; ++x) {
            vec2 neighbor = vec2(float(x), float(y)); // Direction in which neighbor cell lies
            vec2 point = random2(uvInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
            vec2 diff = neighbor + point - uvFract; // Distance between fragment coord and neighbor’s Voronoi point
            float dist = length(diff);
//            minDist = min(minDist, dist);

            if (dist < minDist) {
                minDist = dist;
                cellPt = neighbor + point + uvInt;
            }
        }
    }
    return cos(minDist * 3.14159 * 0.5);
}

float surflet3D(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    vec3 v1 = 6.f * vec3(pow(t2[0], 5.f),
                                    pow(t2[1], 5.f),
                                    pow(t2[2], 5.f));
    vec3 v2 = 15.f * vec3(pow(t2[0], 4.f),
                                    pow(t2[1], 4.f),
                                    pow(t2[2], 4.f));
    vec3 v3 = 10.f * vec3(pow(t2[0], 3.f),
                                    pow(t2[1], 3.f),
                                    pow(t2[2], 3.f));
    vec3 t = vec3(1.f) - v1 + v2 - v3;
    // Get the random vector for the grid point (assume we wrote a function random2
    // that returns a vec2 in the range [0, 1])
    vec3 gradient = random3(gridPoint) * 2.f - vec3(1.f);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}

float perlinNoise3D(vec3 p) {
    float surfletSum = 0.f;
    // Iterate over the eight integer corners surrounding a 3D grid cell
    for(int dx = 0; dx <= 1; ++dx) {
        for(int dy = 0; dy <= 1; ++dy) {
            for(int dz = 0; dz <= 1; ++dz) {
                surfletSum += surflet3D(p, floor(p) + vec3(dx, dy, dz));
            }
        }
    }
    return surfletSum;
}

float interpNoise1D(vec3 p) {
    vec3 intP = floor(p);
    vec3 fractP = fract(p);

    float v1 = random1(intP);
    float v2 = random1(intP + vec3(1.0));
    return smoothstep(v1, v2, fractP.z);
}

float worleyNoise3D(vec3 p)
{
    // Tile the space
    vec3 pointInt = floor(p);
    vec3 pointFract = fract(p);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int z = -1; z <= 1; z++)
    {
        for(int y = -1; y <= 1; y++)
        {
            for(int x = -1; x <= 1; x++)
            {
                vec3 neighbor = vec3(float(x), float(y), float(z));

                // Random point inside current neighboring cell
                vec3 point = random3(pointInt + neighbor);

                // Animate the point
                point = 0.5 + 0.5 * sin(u_Time * 0.01 + 6.2831 * point); // 0 to 1 range

                // Compute the distance b/t the point and the fragment
                // Store the min dist thus far
                vec3 diff = neighbor + point - pointFract;
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}

vec3 fbmOrig(vec3 uv)
{
  float amplitude = 0.05;
  float frequency = 2.;
  vec3 y = sin(uv * frequency);
  float t = 0.01*(-u_Time);
  y += sin(uv*frequency*2.1 + t)*4.5;
  y += sin(uv*frequency*1.72 + t*1.121)*4.0;
  y += sin(uv*frequency*2.221 + t*0.437)*5.0;
  y += sin(uv*frequency*3.1122+ t*4.269)*2.5;
  y = y * 0.5f + 0.5f;
  return y * amplitude;
}

// Value Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

/***************************************************************
 * Toolbox Functions from CIS5660 Slides
 ***************************************************************
*/
/**********************  Basic easing  ***********************/
float easeLinear(float time, float start, float end, float duration) {
    return end * (time / duration) + start;
}

float easeInQuadratic(float t) {
    return t * t;
}

float easeQuadratic(float time, float start, float end, float duration) {
    time = time / duration;
    time = easeInQuadratic(time);
    return time * (end - start) + start;
}

float easeOutQuadratic(float t) {
    return 1.0 - easeInQuadratic(1.0 - t);
}

float easeInOutQuadratic(float t) {
    if (t < 0.5) {
        return easeInQuadratic(t * 2.0) / 2.0;
    } else {
        return 1.0 - easeInQuadratic((1.0 - t) * 2.0) / 2.0;
    }
}

/**********************  Smoother step  ***********************/
float smootherstep(float edge0, float edge1, float x) {
    // scale, bias and saturate x to 0~1 range
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    // evaluate polynomial
    return x*x*x*(x*(x*6.0 - 15.0) + 10.0);
}

/**********************  Bias and Gain  ***********************/
float bias(float b, float t) {
    return pow(t, log(b) / log(0.5));
}

float gain(float g, float t) {
    if (t < 0.5) {
        return bias(1.0-g, 2.0*t) / 2.0;
    } else {
        return 1.0 - bias(1.0 - g, 2.0 - t* 2.0) / 2.0;
    }
}

/**********************  Waves  ***********************/
float squareWave(float x, float freq, float amp) {
    return abs(mod(floor(x * freq), 2.0) * amp);
}

float sawtoothWave(float x, float freq, float amp) {
    return (x * freq - floor(x * freq)) * amp;
}

float triangleWave(float x, float freq, float amp) {
    return abs(mod((x * freq), amp) - (0.5 * amp));
}

/**********************  Pulse  ***********************/
float cubicPulse(float c, float w, float x) {
    x = abs(x-c);
    if (x>w) return 0.0;
    x /= w;
    return 1.0 - x*x*(3.0-2.0*x);
}

/**********************  Parabola  ***********************/
float parabola(float x, float k) {
    return pow(4.0*x*(1.0-x), k);
}

/**********************  Impulse  ***********************/
float impulse(float k, float x) {
    float h = k*x;
    return h * exp(1.0-h);
}

/**********************  Power Curve  ***********************/
float pCurve(float x, float a, float b) {
    float k = pow(a+b, a+b) / (pow(a, a) * pow(b, b));
    return k * pow(x, a) * pow(1.0-x, b);
}