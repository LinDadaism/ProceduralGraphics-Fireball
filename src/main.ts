import {vec2, vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Rectangle from './geometry/Rectangle';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene,   // A function pointer, essentially
  colorRGB: [200, 50, 30],  // RGB array, default to red
  'Background': true,
  'Deformation': true,
};

let icosphere: Icosphere;
let square: Rectangle;
let cube: Cube;
let prevTesselations: number = 5;

let icospherePos = vec3.fromValues(0, 0, 0);
let cubePos = vec3.fromValues(0, -1.5, 0);
let icosphereRadius = 1;
let cubeScale = 1;
let timer: number = 0;

function convertRGBToVec4(r: number, g: number, b: number) {
  return vec4.fromValues(r/255, g/255, b/255, 1);
}

function loadScene() {
  icosphere = new Icosphere(icospherePos, icosphereRadius, controls.tesselations);
  icosphere.create();
  square = new Rectangle(vec3.fromValues(0, 0, 0), window.innerWidth, window.innerHeight);
  square.create();
  cube = new Cube(cubePos, cubeScale);
  cube.create();
  // timer = 0;
}

function main() {
  window.addEventListener('keypress', function (e) {
    // console.log(e.key);
    switch(e.key) {
      // Use this if you wish
    }
  }, false);

  window.addEventListener('keyup', function (e) {
    switch(e.key) {
      // Use this if you wish
    }
  }, false);


  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.addColor(controls, 'colorRGB');
  gui.add(controls, 'Background');
  gui.add(controls, 'Deformation');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  const disco = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/custom-frag.glsl')),
  ]);
  
  function processKeyPresses() {
    // Use this if you wish
  }

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(icospherePos, 1, prevTesselations);
      icosphere.create();
    }

    // pass custom color to shaders
    let color = convertRGBToVec4.apply(null, controls.colorRGB);
    disco.setGeometryColor(color);
    disco.setTime(timer);
    disco.setToggles(controls['Background'], controls.Deformation);
    flat.setToggles(controls['Background'], controls.Deformation);

    gl.disable(gl.DEPTH_TEST);
    renderer.render(camera, flat, [
      square,
    ], timer);

    gl.enable(gl.DEPTH_TEST);
    renderer.render(camera, disco, [
      icosphere,
    ], timer);

    timer += 0.005;
    //timer = timer + 1.0 / stats.getFPS();
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
    flat.setDimensions(window.innerWidth, window.innerHeight);
    disco.setDimensions(window.innerWidth, window.innerHeight);
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();
  flat.setDimensions(window.innerWidth, window.innerHeight);
  disco.setDimensions(window.innerWidth, window.innerHeight);

  // Start the render loop
  tick();
}

main();
