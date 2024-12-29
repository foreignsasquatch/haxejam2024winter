package actors;

import Raylib.Color;
import Raylib.Vector2;

class Bullet {
  public var x:Float;
  public var y:Float;
  public var direction = 1;
  public var speed = 10;
  public var killed = false;
  public var color:Color;

  public function new(x:Float, y:Float, direction:Int) {
    this.x = x;
    this.y = y;
    this.direction = direction;
      this.color = Raylib.Colors.WHITE;
  }

  public function update() {

  }
  
  public function draw() {
    x += speed * direction;

    if((y+32) < 180) killed = true;
    if(x > 420) killed = true;
    if(x < 28) killed = true;

    for(e in Game.enemies) {
      if(Raylib.checkCollisionCircleRec(Vector2.create(x, y), 8, Raylib.Rectangle.create(e.x, e.y, 32, 32))) {
        killed = true;
        // e.hit(0);
      }
    }

    Raylib.drawCircleLines(Std.int(x+8), Std.int(y+8), 16, Raylib.Color.create(255, 231, 214, 255));
    for(i in 0...Raylib.getRandomValue(1, 4)) {
        var xx = x - 8 + Raylib.getRandomValue(5, 50);
        var yx = y  - 8 + Raylib.getRandomValue(5, 30);
        Raylib.drawCircleLines(Std.int(xx), Std.int(yx), Raylib.getRandomValue(8, 16), Raylib.Color.create(255, 38, 116, 255));
    }
    // Raylib.drawCircle(Std.int(x), Std.int(y), 8, color);
  }
}