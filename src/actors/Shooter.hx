package actors;

import engine.Sprite;
import engine.Assets;

class Shooter extends Enemy {
  var spd = 1;
  public var spr:Sprite;
  var bullets:Array<Bullet> = [];

  public function new(x:Float, y:Float) {
    super();
    this.x = x;
    this.y = y;

    spr = new Sprite("content/shooter.ase", x, y);
  }

  var t =0.;
  override function update() {
    super.update();

    var p = Game.player;
    if(!isHit) {
    // if(x < p.x){ x += spd; spr.direction = 1;}
    // else if(x > p.x) {x -= spd; spr.direction = -1;}

    // if(y < p.y) y += spd;
    // else if(y > p.y) y -= spd;
    var r = Raylib.getRandomValue(0, 3);
    t+=Raylib.getFrameTime();
    if(t >= 3) {
      var b = new Bullet(x, y+16, spr.direction);
      b.color = Raylib.Color.create(214, 26, 17, 255);
      bullets.push(b);
    }
    } else {
      x += 20 * -spr.direction;
      if((y+32) < 180) killed = true;
      if(x > 420) killed = true;
      if(x < 28) killed = true;
    }

    spr.x = x;
    spr.y = y;
  }
  
  var h = true;
  override function draw() {
    if(h) {hy += 0.1008181881 + (Raylib.getRandomValue(0, 2)/10); if(hy >= 3) h = false;}
    else {hy -= 0.1008181818 + (Raylib.getRandomValue(0, 2)/10); if(hy <= 0) h = true;}
    spr.y += hy;
    // Raylib.drawTexture(Assets.images["content/shooter.ase"].spritesheet, Std.int(x), Std.int(y), Raylib.Colors.WHITE);
    spr.draw();
    // if(isHit) Raylib.drawLine(Std.int(hx+(32*-spr.direction)), Std.int(hy+16), Std.int(x+(32*-spr.direction)), Std.int(y+16), Raylib.Colors.WHITE); 
  }
}