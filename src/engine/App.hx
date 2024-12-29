package engine;

import cpp.Pointer;
import kui.themes.MaterialDark;
import kui.Style;
import kui.KumoUI;
import kui.impl.KumoRaylib;
import emscripten.Emscripten;
import Raylib.Rectangle;
import Raylib;

class App {
  public static var title:String;
  public static var width:Int;
  public static var height:Int;

  public static var displayWidth:Int;
  public static var displayHeight:Int;
  static var displayTarget:RenderTexture;
  public static var displayRatio:Float;
  static var srcRectangle:Rectangle;
  static var dstRectangle:Rectangle;

  public static var framerate:Int;
  public static var fixedUpdateRate:Int;
  static var timeCounter:Float;
  static var timeStep:Float;

  public static var activeModule:Module = null;

  static var editor:Editor;

  static var shader:Shader;
  static var secondsLoc:Int;
  static var fs = 
"#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform float seconds;

// Output fragment color
out vec4 finalColor;

// NOTE: values should be passed from code
const float vignetteOpacity = 1.0;
const float scanLineOpacity = 0.5;
const float curvature = 10.0;
const float distortion = 0.1;
const float gammaInput = 2.4;
const float gammaOutput = 2.2;
const float brightness = 1.5;
const float screenw = 960.0;
const float screenh = 720.0;

vec2 curveRemapUV() {
  vec2 uv = fragTexCoord*2.0-1.0;
  vec2 offset = abs(uv.yx)/curvature;
  uv = uv + uv*offset*offset;
  uv = uv*0.5 + 0.5;
  return uv;
}

vec3 vignetteIntensity(vec2 uv, vec2 resolution, float opacity) {
  float intensity = uv.x*uv.y*(1.0 - uv.x)*(1.0 - uv.y);
  return vec3(clamp(pow(resolution.x*intensity, opacity), 0.0, 1.0));
}

vec3 scanLineIntensity(float uv, float resolution, float opacity) {
  float intensity = sin(uv*resolution*2.0);
  intensity = ((0.5*intensity) + 0.5)*0.9 + 0.1;
  return vec3(pow(intensity, opacity));
}

vec3 distortIntensity(vec2 uv, float time) {
  vec2 rg = sin(uv*10.0 + time)*distortion + 1.0;
  float b = sin((uv.x + uv.y)*10.0 + time)*distortion + 1.0;
  return vec3(rg, b);
}

void main() {
  vec2 uv = curveRemapUV();
  vec2 size = vec2(screenw, screenh);
  vec3 baseColor = texture(texture0, uv).rgb;
  baseColor *= vignetteIntensity(uv, size, vignetteOpacity);
  baseColor *= distortIntensity(uv, seconds);
  baseColor = pow(baseColor, vec3(gammaInput)); // gamma correction
  baseColor *= scanLineIntensity(uv.x, size.x, scanLineOpacity);
  baseColor *= scanLineIntensity(uv.y, size.y, scanLineOpacity);
  baseColor = pow(baseColor, vec3(1.0/gammaOutput)); // gamma correction
  baseColor *= vec3(brightness);

  if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
    finalColor = vec4(0.0, 0.0, 0.0, 1.0);
  } else {
    finalColor = vec4(baseColor, 1.0);
  }
}";

static var fsweb = 
"#version 100

precision highp float;

// Input vertex attributes (from vertex shader)
varying vec2 fragTexCoord;
varying vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform float seconds;

// Output fragment color
//varying vec4 finalColor;

// NOTE: values should be passed from code
const float vignetteOpacity = 1.0;
const float scanLineOpacity = 0.5;
const float curvature = 10.0;
const float distortion = 0.1;
const float gammaInput = 2.4;
const float gammaOutput = 2.2;
const float brightness = 1.5;
const float screenw = 960.0;
const float screenh = 720.0;

vec2 curveRemapUV() {
vec2 uv = fragTexCoord*2.0-1.0;
vec2 offset = abs(uv.yx)/curvature;
uv = uv + uv*offset*offset;
uv = uv*0.5 + 0.5;
return uv;
}

vec3 vignetteIntensity(vec2 uv, vec2 resolution, float opacity) {
float intensity = uv.x*uv.y*(1.0 - uv.x)*(1.0 - uv.y);
return vec3(clamp(pow(resolution.x*intensity, opacity), 0.0, 1.0));
}

vec3 scanLineIntensity(float uv, float resolution, float opacity) {
float intensity = sin(uv*resolution*2.0);
intensity = ((0.5*intensity) + 0.5)*0.9 + 0.1;
return vec3(pow(intensity, opacity));
}

vec3 distortIntensity(vec2 uv, float time) {
vec2 rg = sin(uv*10.0 + time)*distortion + 1.0;
float b = sin((uv.x + uv.y)*10.0 + time)*distortion + 1.0;
return vec3(rg, b);
}

void main() {
vec2 uv = curveRemapUV();
vec2 size = vec2(screenw, screenh);
vec3 baseColor = texture2D(texture0, uv).rgb;
baseColor *= vignetteIntensity(uv, size, vignetteOpacity);
baseColor *= distortIntensity(uv, seconds);
baseColor = pow(baseColor, vec3(gammaInput)); // gamma correction
baseColor *= scanLineIntensity(uv.x, size.x, scanLineOpacity);
baseColor *= scanLineIntensity(uv.y, size.y, scanLineOpacity);
baseColor = pow(baseColor, vec3(1.0/gammaOutput)); // gamma correction
baseColor *= vec3(brightness);

if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
} else {
  gl_FragColor = vec4(baseColor, 1.0);
}
}";

  public function new(cfg:{title:String, display:{w:Int, h:Int}, desktop:{w:Int, h:Int}, web:{w:Int, h:Int}}) {
    title = cfg.title;

    #if wasm
    width = cfg.web.w;
    height = cfg.web.h;
    #else
    width = cfg.desktop.w;
    height = cfg.desktop.h;
    #end

    displayWidth = cfg.display.w;
    displayHeight = cfg.display.h;

    framerate = 60;
    fixedUpdateRate = 60;

    timeStep = 1/fixedUpdateRate;
  }

  static var ui:KumoRaylib;
  public function run(m:Class<Module>) {
    // Raylib.setTraceLogLevel(7);
    Raylib.setConfigFlags(ConfigFlags.VSYNC_HINT);
    Raylib.initWindow(width, height, title);
    Raylib.initAudioDevice();

    displayRatio = width / displayWidth;

    Raylib.setTargetFPS(framerate);
    Raylib.setExitKey(Keys.NULL);

    var font = KumoRaylib.loadFontSDF("content/firacode.ttf");
    var fontb = KumoRaylib.loadFontSDF("content/firacode-bold.ttf");
    ui = new KumoRaylib(font, fontb, true);
    // Style.instance = new MaterialDark();

    Assets.load('content/__library__.json');

    editor = new Editor();

    displayTarget = Raylib.loadRenderTexture(displayWidth, displayHeight);
    srcRectangle = Rectangle.create(0, 0, displayWidth, -displayHeight);
    dstRectangle = Rectangle.create(-displayRatio, -displayRatio, width + (displayRatio * 2), height + (displayRatio * 2));

    #if wasm
    shader = Raylib.loadShaderFromMemory(null, fsweb);
    #else
    shader = Raylib.loadShaderFromMemory(null, fs);
    #end
    var screenSize = [Raylib.getScreenWidth(), Raylib.getScreenHeight()];
     secondsLoc =  Raylib.getShaderLocation(shader, "seconds");

    setModule(m);

    #if wasm
    Emscripten.set_main_loop(cpp.Callable.fromStaticFunction(update), 60, true);
    #else
    while(!Raylib.windowShouldClose()) {
        update();
    }
    #end

    Raylib.unloadRenderTexture(displayTarget);

    Assets.unload();
    Raylib.closeAudioDevice();
    Raylib.closeWindow();
  }


  static var seconds = 0.;
static function update() {
  seconds += Raylib.getFrameTime();
  Raylib.setShaderValue(shader, secondsLoc, cast Pointer.addressOf(seconds).raw, Raylib.ShaderUniform.FLOAT);
    #if debug
    if (Raylib.isKeyPressed(Raylib.Keys.F5)) Editor.active = !Editor.active;
    if(Editor.active) {
      if(Raylib.getScreenWidth() != 1600) {
          Raylib.setWindowSize(1600, 900);
          Raylib.showCursor();
          Raylib.enableCursor();
      }
    } else {
      if(Raylib.getScreenWidth() != width) Raylib.setWindowSize(width, height);
    }
    #end

    timeCounter += Raylib.getFrameTime();
    while(timeCounter > timeStep) {
      if(Editor.active) editor.update();
     else activeModule.update();
        timeCounter -= timeStep;
    }

    Raylib.beginTextureMode(displayTarget);
    Raylib.clearBackground(Raylib.Colors.BLACK);
    if(!Editor.active) activeModule.draw();
    Raylib.endTextureMode();

    Raylib.beginDrawing();
    Raylib.clearBackground(Colors.RED);
    Raylib.beginShaderMode(shader);
    Raylib.drawTexturePro(displayTarget.texture, srcRectangle, dstRectangle, Vector2.zero(), 0, Colors.WHITE);
    Raylib.endShaderMode();
    if(Editor.active) editor.draw();

    ui.begin();
    if(!Editor.active) {
      activeModule.ui();
    }
    else editor.ui();
    ui.end();
    Raylib.endDrawing();
  }

  public static function setModule(m:Class<Module>) {
    activeModule = null;
    activeModule = Type.createInstance(m, []);
  }
}