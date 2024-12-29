package actors;

class Enemy {
  public var x:Float;
  public var y:Float;
  public var health:Int = 2;
  public var isHit = false;
  var killed = false;
  var color = Raylib.Colors.WHITE;
  var hx = 0.;
  var hy = 0.;

  public function new() {
  }

  public function update() {
  }

  public function draw() {
  }

  public function hit(i:Int) {
    health -= i;
    isHit = true;
    color = Raylib.Colors.WHITE;
    hx = x;
    hy = y;
  }
}