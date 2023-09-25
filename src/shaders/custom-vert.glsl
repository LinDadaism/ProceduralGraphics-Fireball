#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time;
uniform vec3 u_Eye, u_Ref, u_Up;
uniform int u_DeformToggle;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Pos;            // The array of vertex positions that has been transformed by u_Model. This is implicitly passed to the fragment shader.
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

INCLUDE_TOOL_FUNCTIONS

#define WORLEY 1
#define PERLIN 0
float fbm(vec3 uv) {
    float sum = 0.0, noise = 0.0;
    float freq = 2.0;
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

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    /************************** Start: Apply deformation ************************/
    fs_Pos = vs_Pos;

    float noiseXY = fbm(vec3(vs_Pos) * cubicPulse(vs_Pos.x, vs_Pos.y, 0.05 * mod(u_Time * 10.0, 3.0)));
    float noiseYX= fbm(vec3(vs_Pos) * cubicPulse(-vs_Pos.y, -vs_Pos.x, 0.1 * mod(u_Time * 10.0, 10.0)));
    float noiseXZ = fbm(vec3(vs_Pos) * cubicPulse(vs_Pos.z, -vs_Pos.x, 0.1 * mod(u_Time * 10.0, 7.0)));
    float noiseZX = fbm(vec3(vs_Pos) * cubicPulse(vs_Pos.z, vs_Pos.x, 0.1 * mod(u_Time * 10.0, 9.0)));

    float noise2 = worleyNoise3D(vec3(vs_Pos))*easeInOutQuadratic(u_Time * 0.1 + 10.0);
    float noise3 = bias(1., noise2) + 0.2;
    
    if (u_DeformToggle > 0)
    {
        fs_Pos += normalize(fs_Nor) * noiseXY * 0.25;
        fs_Pos -= normalize(fs_Nor) * noiseYX * 0.25;
        fs_Pos += normalize(fs_Nor) * noiseXZ * 0.25;
        fs_Pos -= normalize(fs_Nor) * noiseZX * 0.25;

        fs_Pos += normalize(fs_Nor) * 0.2 * noise3;
    }

    /************************** End: Apply deformation ************************/

    vec4 modelposition = u_Model * fs_Pos;   // Temporarily store the transformed vertex positions for use below
    fs_Pos = modelposition;

    //fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
