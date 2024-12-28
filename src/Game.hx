import Raylib.Font;
import actors.Enemy;
import Raylib.Vector2;
import Raylib.Color;
import actors.Shooter;
import Raylib.Music;
import Raylib.Texture;
import kui.KumoUI;
import actors.Player;
import engine.Assets;
import engine.Module;

class Game implements Module {
  public static var isPlayerTurn = true;
  public static var player:Player;
  public static var enemies:Array<Enemy> = [];

  public var startPlay = false;

  var bg:Texture;
  var details:Texture;
  var cursor:Texture;
  var ambient:Music;

  var font:Font;

  public function new() {
    // Raylib.hideCursor();
    // Raylib.disableCursor();

    font = Raylib.loadFont("content/m6x11.ttf");

    player = new Player();
    bg = Raylib.loadTexture("content/bg.png");
    details = Raylib.loadTexture("content/details.png");
    cursor = Raylib.loadTexture("content/cursor.png");
    ambient = Raylib.loadMusicStream("content/ambient.mp3");
    ambient.looping = true;
    // Raylib.playMusicStream(ambient);
    Raylib.setMusicVolume(ambient, 10);

    // enemies.push(new Shooter());
    for(i in 0...4) {
      var e = new Shooter(148 + Raylib.getRandomValue(-20, 30), 188 + (32 * i));
      var t = Raylib.getRandomValue(0, 2);
      if(t == 0) {e.spr.tint = Raylib.Color.create(214, 36, 17, 255); e.spr.direction = -1;}
      else if(t==1) e.spr.tint = Raylib.Color.create(255, 128, 164, 255);
      else {e.spr.tint = Raylib.Color.create(16, 210, 177, 255); e.spr.direction = 1;}
      enemies.push(e);
    }
    trace(enemies);
  }

  public function update() {
    Raylib.updateMusicStream(ambient);
    player.update();
    for(s in enemies) s.update();
  }

  var hy = 0.;
  var h = true;
  var by = 0.;
  var b = true;
  var mpos = Vector2.zero();
  public function draw() {
    if(h) {hy += 0.1008181881; if(hy >= 3) h = false;}
    else {hy -= 0.1008181818; if(hy <= 0) h = true;}

    if(b) {by += 0.2008181881; if(by >= 5) b = false;}
    else {by -= 0.2008181818; if(by <= 0) b = true;}

    // background
    Raylib.drawRectangle(0, 0, 480, 360, Raylib.Color.create(22, 23, 26, 255));
    Raylib.drawTexture(bg, 0, 0, Raylib.Colors.WHITE); // non dynamic bg elements
    Raylib.drawTexture(details, 0, 0, Raylib.Colors.WHITE);
    Raylib.drawTexture(Assets.images["content/boss.ase"].spritesheet, 126, Std.int(46+by), Raylib.Colors.WHITE);
    Raylib.drawTexture(Assets.images["content/bosshead.ase"].spritesheet, 188, Std.int(48+hy), Raylib.Colors.WHITE);
    Raylib.drawTexture(Assets.images["content/table.ase"].spritesheet, 126, 46, Raylib.Colors.WHITE);

    for(s in enemies) s.draw();
    player.draw();
    // Raylib.drawTexture(Assets.images["content/sketch1.ase"].spritesheet, 0, 0, Raylib.Colors.WHITE);
    // phone();

    mpos = Vector2.create(lerp(mpos.x, Raylib.getMouseX()-8, 0.2), lerp(mpos.y, Raylib.getMouseY()-8, 0.2));
    // Raylib.drawTextureV(cursor, mpos, Raylib.Colors.WHITE);
  }

  public function ui() {
    Raylib.drawFPS(0, 0);
    Raylib.drawText('${player.debt}', 100, 0, 32, Raylib.Colors.RED);
  }

  function phone() {
    Raylib.drawTexture(Assets.images["content/ui.ase"].spritesheet, Raylib.getRandomValue(386, 387), Raylib.getRandomValue(265, 267), Raylib.Colors.WHITE);
    Raylib.drawCircle(392+4, 284+4, 4, Raylib.Color.create(250, 253, 255, 255));
  }

  function lerp(a:Float, b:Float, f:Float) {
    return a + f * (b - a);
  }

  function grid(x:Float, y:Float, w:Float, h:Float, size:Int, c:Color) {
    // x
    for(i in 0...Std.int(w / size)) {
        var gx = Std.int(x + i * size);
        Raylib.drawLine(gx, Std.int(y), gx, Std.int(y + h), c);
    }
  
    // y
    for(i in 0...Std.int(h / size)) {
        var gy = Std.int(y + i * size);
        Raylib.drawLine(Std.int(x), gy, Std.int(x + w), gy, c);
    }
  }

  public static function moveTowards(v:Vector2, target:Vector2, maxDistance:Float) {
    var result = Vector2.zero();

    var dx = target.x - v.x;
    var dy = target.y - v.y;
    var value = (dx*dx) + (dy*dy);

    if ((value == 0) || ((maxDistance >= 0) && (value <= maxDistance*maxDistance))) return target;

    var dist = Math.sqrt(value);

    result.x = v.x + dx/dist*maxDistance;
    result.y = v.y + dy/dist*maxDistance;

    return result;
  }

  function text(t:String, x:Float, y:Float, s:Int, c:Color) {
    Raylib.drawTextEx(font, t, Raylib.Vector2.create(Std.int(x), Std.int(y)), s, 0, c);
  }
}