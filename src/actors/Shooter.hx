package actors;

import engine.Sprite;
import engine.Assets;

class Shooter extends Enemy {
  var spd = 1;
  public var spr:Sprite;
  var bullets:Array<Bullet> = [];
  var dx = 0.0;

  public function newhit() {
  }

  public function new(x:Float, y:Float) {
    super();
    this.x = x;
    this.y = y;

    spr = new Sprite("content/shooter.ase", x, y);
  }
  var t =0.;
  override function update() {
      // if((y+32) < 180) killed = true;
      // if(x > 420) killed = true;
      // if(x < 28) killed = true;
    spr.x = x;
    spr.y = y;
  }
  
  var h = true;
  override function draw() {
    // if(h) {hy += 0.1008181881 + (Raylib.getRandomValue(0, 2)/10); if(hy >= 3) h = false;}
    // else {hy -= 0.1008181818 + (Raylib.getRandomValue(0, 2)/10); if(hy <= 0) h = true;}
    // spr.y += hy;
    // Raylib.drawTexture(Assets.images["content/shooter.ase"].spritesheet, Std.int(x), Std.int(y), Raylib.Colors.WHITE);
    spr.draw();
    // if(isHit) Raylib.drawLine(Std.int(hx+(32*-spr.direction)), Std.int(hy+16), Std.int(x+(32*-spr.direction)), Std.int(y+16), Raylib.Colors.WHITE); 
  }
}