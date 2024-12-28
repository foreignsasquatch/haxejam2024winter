package engine;

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
    Raylib.setTraceLogLevel(7);
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


static function update() {
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
    Raylib.drawTexturePro(displayTarget.texture, srcRectangle, dstRectangle, Vector2.zero(), 0, Colors.WHITE);
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