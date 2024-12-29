package actors;

import engine.Sprite;
import haxe.ds.Vector;
import engine.App;
import Raylib;
import Raylib.Vector2;
import engine.Assets;

typedef Vec = {x:Float, y:Float};

// fishing gun u shoot and pull to kill them  
class Player {
  public var x:Float;
  public var y:Float;
  public var dx:Float;
  public var dy:Float;
  public var accX:Float;
  public var accY:Float;
  public var friction = 0.7817271231;

  public var speed:Float = 3;

  public var sprite:Sprite;

  var bullets:Array<Bullet> = [];

  public var debt = 2048;

  public function new() {
    x = 230;
    y = 270;

    dx = 0;
    dy = 0;

    sprite = new Sprite("content/player.ase", x, y);
  }

  var mposX = 0.;
  var mposY = 0.;
  var a = 0.8;
  public function update() {
      mposX = Raylib.getMouseX();
      mposY = Raylib.getMouseY();

      if(Raylib.isKeyDown(Raylib.Keys.LEFT)) accX = -a;
      else if(Raylib.isKeyDown(Raylib.Keys.RIGHT)) accX = a;
      else accX = 0;

      if(Raylib.isKeyDown(Raylib.Keys.UP)) accY = -a;
      else if(Raylib.isKeyDown(Raylib.Keys.DOWN)) accY = a;
      else accY = 0;

      dx *= friction;
      dy *= friction;
      dx += accX;
      dy += accY;

      if(dx > speed) dx = speed;
      else if(dx < -speed) dx = -speed;

      if(dy > speed) dy = speed;
      else if(dy < -speed) dy = -speed;

      x += dx;
      y += dy;
      sprite.x = x;
      sprite.y = y;

      if((y) < 180) y = 180;
      if(x > 420) x = 420;
      if(x < 28) x = 28;
      if((y+32) > 360) y = 360-32;

      // if(Raylib.isKeyPressed(Raylib.Keys.X))  {

      // }

      for(b in bullets) if(b.killed) bullets.remove(b);

      if(debt <= 0) trace("won");
  }

  public function draw() {
    if(dx > 0) sprite.direction = -1;
    else sprite.direction = 1;

    sprite.draw();
    for(b in bullets) b.draw();
    // Raylib.drawTextureV(Assets.images["content/player.ase"].spritesheet, Vector2.create(Std.int(x), Std.int(y)), Raylib.Colors.WHITE);

    // highlight attack
    // for(s in Game.enemies) {
    //   if(Raylib.checkCollisionPointRec(Vector2.create(mposX, mposY), Rectangle.create(s.x, s.y, 32, 32))) {
    //     Raylib.drawCircleLines(Std.int(s.x+16), Std.int(s.y+12), 8, Raylib.Color.create(250, 253, 255, 255));
    //     // Raylib.drawCircleLines(Std.int(s.x+16), Std.int(s.y+12), 12, Raylib.Color.create(250, 253, 255, 255));

    //     if(Raylib.isMouseButtonReleased(MouseButton.LEFT)) {
    //     }
    //   }
    // }
  }

  public function shoot() {
    // if(sprite.direction == -1) bullets.push(new Bullet(x+32, y+16, -sprite.direction));
    // else bullets.push(new Bullet(x, y+16, -sprite.direction));
  }

  public function move() {
  }
}