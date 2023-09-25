import {vec2, vec3, vec4, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    if (source.indexOf("INCLUDE_TOOL_FUNCTIONS") > 0) {
      source = source.replace("INCLUDE_TOOL_FUNCTIONS", require('../../shaders/toolbox.glsl'));
    }

    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifRef: WebGLUniformLocation;
  unifEye: WebGLUniformLocation;
  unifUp: WebGLUniformLocation;
  unifDimensions: WebGLUniformLocation;

  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifColor: WebGLUniformLocation;
  unifTime: WebGLUniformLocation;
  unifBgToggle: WebGLUniformLocation;
  unifDeformToggle: WebGLUniformLocation;

  unifBgSpeed: WebGLUniformLocation;
  unifBgDist: WebGLUniformLocation;
  unifBgZoom: WebGLUniformLocation; 
  unifFbmFreq: WebGLUniformLocation;
  unifFbmAmp: WebGLUniformLocation;
  unifFbmOct: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    
    this.unifEye   = gl.getUniformLocation(this.prog, "u_Eye");
    this.unifRef   = gl.getUniformLocation(this.prog, "u_Ref");
    this.unifUp   = gl.getUniformLocation(this.prog, "u_Up");
    this.unifDimensions   = gl.getUniformLocation(this.prog, "u_Dimensions");
    this.unifTime   = gl.getUniformLocation(this.prog, "u_Time");

    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifColor      = gl.getUniformLocation(this.prog, "u_Color");
    this.unifBgToggle   = gl.getUniformLocation(this.prog, "u_BgToggle");
    this.unifDeformToggle = gl.getUniformLocation(this.prog, "u_DeformToggle");
  
    this.unifBgSpeed = gl.getUniformLocation(this.prog, "u_BgSpeed");;
    this.unifBgDist = gl.getUniformLocation(this.prog, "u_BgDist");;
    this.unifBgZoom = gl.getUniformLocation(this.prog, "u_BgZoom");; 
    this.unifFbmFreq = gl.getUniformLocation(this.prog, "u_FbmFreq");;
    this.unifFbmAmp = gl.getUniformLocation(this.prog, "u_FbmAmp");;
    this.unifFbmOct = gl.getUniformLocation(this.prog, "u_FbmOct");;
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setEyeRefUp(eye: vec3, ref: vec3, up: vec3) {
    this.use();
    if(this.unifEye !== -1) {
      gl.uniform3f(this.unifEye, eye[0], eye[1], eye[2]);
    }
    if(this.unifRef !== -1) {
      gl.uniform3f(this.unifRef, ref[0], ref[1], ref[2]);
    }
    if(this.unifUp !== -1) {
      gl.uniform3f(this.unifUp, up[0], up[1], up[2]);
    }
  }

  setDimensions(width: number, height: number) {
    this.use();
    if(this.unifDimensions !== -1) {
      gl.uniform2f(this.unifDimensions, width, height);
    }
  }

  setTime(t: number) {
    this.use();
    if(this.unifTime !== -1) {
      gl.uniform1f(this.unifTime, t);
    }
  }

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setGeometryColor(color: vec4) {
    this.use();
    if (this.unifColor !== -1) {
      gl.uniform4fv(this.unifColor, color);
    }
  }

  setToggles(bg: boolean, deform: boolean) {
    this.use();
    if (this.unifBgToggle !== -1) {
      gl.uniform1i(this.unifBgToggle, bg ? 1 : -1);
    }

    if (this.unifDeformToggle !== -1) {
      gl.uniform1i(this.unifDeformToggle, deform ? 1 : -1);
    }
  }

  setNoiseValues(bgSpeed: number, bgDist: number, bgZoom: number, 
    fbmFreq: number, fbmAmp: number, fbmOct: number) {
    this.use();
    if (this.unifBgSpeed !== -1) {
      gl.uniform1f(this.unifBgSpeed, bgSpeed);
    }
    if (this.unifBgDist !== -1) {
      gl.uniform1f(this.unifBgDist, bgDist);
    }
    if (this.unifBgZoom !== -1) {
      gl.uniform1f(this.unifBgZoom, bgZoom);
    }
    if (this.unifFbmFreq !== -1) {
      gl.uniform1f(this.unifFbmFreq, fbmFreq);
    }
    if (this.unifFbmAmp !== -1) {
      gl.uniform1f(this.unifFbmAmp, fbmAmp);
    }
    if (this.unifFbmOct !== -1) {
      gl.uniform1i(this.unifFbmOct, fbmOct);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
  }
};

export default ShaderProgram;
