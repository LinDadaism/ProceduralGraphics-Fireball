#version 300 es
precision highp float;

// The vertex shader used to render the background of the scene
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

in vec4 vs_Pos;
out vec2 fs_Pos;

void main() {
  vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below
  fs_Pos = modelposition.xy;

  // fs_Pos = vs_Pos.xy;
  gl_Position = u_ViewProj * modelposition;
}
