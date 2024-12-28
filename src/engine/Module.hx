package engine;

interface Module {
  public function update():Void;
  public function draw():Void;
  public function ui():Void;
}