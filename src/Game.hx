import engine.App;
import Raylib.Sound;
import Raylib.RlVector2;
import Raylib.Camera2D;
import Raylib.Camera;
import haxe.Timer;
import sys.io.File;
import Raylib.Keys;
import Raylib.TextureFilter;
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

// you have a bar and then middle it is separated as player and enemy
// the player types and the bar goes forward and every 5s the enemy bar goes forward
// player bar goes forward for every line he types
class Game implements Module {
  public static var isPlayerTurn = true;
  public static var player:Player;
  public static var enemies:Array<Shooter> = [];

  var camera:Camera2D;
  var cameraShake = false;

  var enemyFiles:Array<String> = [File.getContent("content/luigi"), File.getContent("content/halfwheat"), File.getContent("content/headm")];
  var enemy = 0;
  var enemyNames = ["Luigi", "H.Wheat", "Haihjks"];
  var enemyProfession = ["Plumber", "Genius", "Princess Vampire"];
  var enemyAmount = 512;
  var currentLinePlayer = 0;
  var currentLineEnemy = 0;
  var currentCharPlayer = 0;
  var currentCharEnemy = 0;

  var canAttack = false;

  var enemyDialogues = [
    "I've been waiting for 2 months now",
    "I have a broken collar bone",
    "I love capitalism",
    "Plastic surgery isn't costly is it"
  ];
  var enemyOnHitDialogues = [
    "Please I have a wife",
    "I love you",
    "I see that doesn't work",
    "You'll pay for this... or i will",
    "Leave me alone please.",
    "I'm pregnant",
    "NOOOOOO",
    "Mah moneh",
    "This is boring take me already",
    "-_-",
    "I'll pay you more if u stop",
    "Get away!!!",
    "Creep, Weirdo",
    "Love when u do that babe"
  ];
  var changeHitDialogue = false;
  var randomdialoguetimer = 0.0;

  public static var startPlay = false;
  var showstart = false;
  public var gameOver = false;

  var bg:Texture;
  var details:Texture;
  var cursor:Texture;
  var ambient:Music;
  var music:Music;
  var typing:Sound;

  var curtain = 360;

  var font:Font;

  public function new() {
    Raylib.hideCursor();
    Raylib.disableCursor();

    camera = Raylib.Camera2D.create(RlVector2.zero(), RlVector2.zero());

    font = Raylib.loadFont("content/quaver.ttf");
    Raylib.setTextureFilter(font.texture, TextureFilter.POINT);

    player = new Player();
    bg = Raylib.loadTexture("content/bg.png");
    details = Raylib.loadTexture("content/details.png");
    cursor = Raylib.loadTexture("content/cursor.png");
    ambient = Raylib.loadMusicStream("content/ambient.mp3");
    ambient.looping = true;
    Raylib.playMusicStream(ambient);
    Raylib.setMusicVolume(ambient, 10);
    music = Raylib.loadMusicStream("content/vishwa_old_beat.wav");
    music.looping = true;
    Raylib.setMusicVolume(music, .4);

    // typing = Raylib.loadSound("content/typing.mp3");

    // enemies.push(new Shooter());
    for(i in 0...3) {
      var e = new Shooter(148 + Raylib.getRandomValue(-20, 30), 188 + (32 * i));
      var t = Raylib.getRandomValue(0, 2);
      if(t == 0) {e.spr.tint = Raylib.Color.create(214, 36, 17, 255); e.spr.direction = -1;}
      else if(t==1) {e.spr.tint = Raylib.Color.create(255, 128, 164, 255);e.spr.direction = 1;}
      else {e.spr.tint = Raylib.Color.create(16, 210, 177, 255); e.spr.direction = 1;}
      enemies.push(e);
    }
  }

  public function update() {
    Raylib.updateMusicStream(ambient);
    Raylib.updateMusicStream(music);
    player.update();
    for(i in 0...enemies.length) {
      var s = enemies[i];
      s.update();
    }

    if(!Raylib.isMusicStreamPlaying(music) && startPlay) Raylib.playMusicStream(music);

    cameraShake = true;
    if(cameraShake) {
      camera.offset.x += Math.cos(Raylib.getTime() * 1.1) * 2.5 * 1.0;
      camera.offset.y += Math.sin(0.3 + Raylib.getTime() * 1.7) * 2.5 * 1.0;
    }
  }

  var hy = 0.;
  var h = true;
  var by = 0.;
  var b = true;
  var mpos = Vector2.zero();
  var edir = 1;
  var hitDialouge:String;
  var killcount = 0;
  var ydir = 1;
  var mult = 1.;
  public function draw() {
  if(!gameOver) {
    Raylib.beginMode2D(camera);
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
    if(killcount > 0) text('...ye were surpposed to collect nort, kill en $killcount people', 255, 47, 8, fg);

    randomdialoguetimer += Raylib.getFrameTime();
    for(s in enemies) {
      if(player.y > s.y && player.y < s.y + 32) s.spr.direction = player.sprite.direction;

      if(!(enemies.indexOf(s) == enemy)) {
        s.draw();
      } 
      if(enemies.indexOf(s) == enemy && !startPlay) {
        s.draw();
      }
      if(enemies.indexOf(s) == 0 && !startPlay) {
        if(s.y > player.y) {s.y -= 1;s.spr.y = s.y;}
        else {}
      }
      // if(randomdialoguetimer >= 10) {
        // var i = Raylib.getRandomValue(0, 3);
        if(!startPlay && enemies.indexOf(s) <= 2) {
          var t = Raylib.measureTextEx(font, enemyDialogues[enemies.indexOf(s)], 8, 0);
          Raylib.drawRectangle(Std.int(s.x-t.x-2), Std.int(s.y-2), Std.int(t.x+2), 10, s.spr.tint);
          text(enemyDialogues[enemies.indexOf(s)], s.x-t.x, s.y, 8, fg);
          randomdialoguetimer = 0;
        }
      // }
    }
    if(!startPlay) player.draw();

    if(!startPlay) {
      if(player.y > 190) text("go to the desk", player.x + 32, player.y, 8, fg);
    }
    // Raylib.drawTexture(Assets.images["content/sketch1.ase"].spritesheet, 0, 0, Raylib.Colors.WHITE);
    // phone();

    mpos = Vector2.create(lerp(mpos.x, Raylib.getMouseX()-8, 0.2), lerp(mpos.y, Raylib.getMouseY()-8, 0.2));
    // Raylib.drawTextureV(cursor, mpos, Raylib.Colors.WHITE);

    if(!startPlay && (player.y < 190)) {
      if(!showstart) text("Press [SPACE] to start", player.x+32, 175, 8, Raylib.Colors.WHITE);
      if(Raylib.isKeyReleased(Keys.SPACE)) {
        showstart = true;
        hitDialouge = enemyOnHitDialogues[0];
      }
    }

    // if(showstart) {
    //   Raylib.drawRectangle()
    // }

    if(startPlay) {
      if(curtain == 0) {
        Raylib.drawRectangle(0, 0, 480, 360, Raylib.Color.create(22, 23, 26, 255));
        Raylib.drawTexture(Assets.images["content/boss.ase"].spritesheet, 126, Std.int(46+by), Raylib.Colors.WHITE);
        Raylib.drawTexture(Assets.images["content/bosshead.ase"].spritesheet, 188, Std.int(48+hy), Raylib.Colors.WHITE);
        Raylib.drawTexture(Assets.images["content/table.ase"].spritesheet, 126, 46, Raylib.Colors.WHITE);

        var e = enemies[enemy];
        e.draw();

        var offx = 64;
        var offy = 0;
        var r = Raylib.Rectangle.create(Std.int(e.x - offx), Std.int(e.y-offy), 128+64, 32);

        if(enemyNames[0] == "Luigi") {
          e.x += 1 * edir;
          e.spr.direction = edir;
          if(e.x > 420) edir = -1;
          if(e.x < 28) edir = 1;
        } else if(enemyNames[0] == "H.Wheat") {
          e.x += 1.5 * 1;
          if(e.spr.direction != 0) e.spr.direction = edir;
          if(e.x > 423) {e.x = 28;}
          r.width = 128 + 64;
          mult =  1.5;
        } else if(enemyNames[0] == "Haihjks") {
          // mult = 1.5;
          e.x += 0.8 * edir;
          e.y += 0.8 * ydir;
          if(e.spr.direction != 0) e.spr.direction = edir;
          if(e.x > 423) {e.x = 28;}
          offx = -80;
          offy = 80;
          r.width = 160;
          if(e.y > 265-32) ydir = -1;
          if(e.y < 180) ydir = 1;
        }

        Raylib.drawRectangleLinesEx(r, 1, e.spr.tint);

        // if(b)
        if(changeHitDialogue) {hitDialouge = enemyOnHitDialogues[Raylib.getRandomValue(0, enemyOnHitDialogues.length-1)]; changeHitDialogue = false;}
        if(enemyAmount < 512) text(hitDialouge, e.x - (Raylib.measureText(hitDialouge, 8)/2), e.y + 40, 8, e.spr.tint);

        if(Raylib.checkCollisionRecs(r, Raylib.Rectangle.create(player.x, player.y, 32, 32))) {
          canAttack = true;
        } else canAttack = false;
        player.draw();
      }
    } 

    Raylib.endMode2D();

    phone();
    panel();
  }
  
    if(!startPlay) {
      curtain -= 8;
      if (curtain <= 0) curtain = 0;
      Raylib.drawRectangle(0, 0, 480, curtain, Raylib.Colors.BLACK);
    }

    curtain -= 8;
    if (curtain <= 0) curtain = 0;
    Raylib.drawRectangle(0, 0, 480, curtain, Raylib.Colors.BLACK);

    if(lineTimer <= 0) {
      gameOver = true;
    }

    if(gameOver) {
      Raylib.pauseMusicStream(music);
      Raylib.drawRectangle(0, 0, 480, 360, Raylib.Colors.BLACK);
      if(enemies.length > 0) text("no insurance for u >:D", 480/2-Raylib.measureText("no insurance for u", 8)/2, 360/2-4, 8, hg); else text("you've won! do die soon for another visit", 480/2-Raylib.measureText("you've won! do die soon for another visiit", 8)/2, 360/2-4, 8, hg);
      if(!(enemies.length == 0))text("press [space] to play again", 480/2-Raylib.measureText("press [space] to play again", 8)/2, 360/2-4+8, 8, hg);
      if(Raylib.isKeyPressed(Raylib.Keys.SPACE) && enemies.length > 0) {
        // App.setModule(Game);
        // enemies = null;
        // enemies = [];
        // for(i in 0...4) {
        //   var e = new Shooter(148 + Raylib.getRandomValue(-20, 30), 188 + (32 * i));
        //   var t = Raylib.getRandomValue(0, 2);
        //   if(t == 0) {e.spr.tint = Raylib.Color.create(214, 36, 17, 255); e.spr.direction = -1;}
        //   else if(t==1) e.spr.tint = Raylib.Color.create(255, 128, 164, 255);
        //   else {e.spr.tint = Raylib.Color.create(16, 210, 177, 255); e.spr.direction = 1;}
        //   enemies.push(e);
        // }
        gameOver = false;
        showstart = false;
        startPlay = false;
        lineTimer = 20;
        curtain = 360;
        enemyAmount = 512;
        currentLinePlayer = 0;
        currentLineEnemy = 0;
        currentCharPlayer = 0;
        currentCharEnemy = 0;
        killcount = 0;
      }
    }
  }

  public function ui() {
    #if debug
    // Raylib.drawFPS(0, 0);
    #end
    // Raylib.drawText('${player.debt}', 100, 0, 32, Raylib.Colors.RED);
  }

  var bgc = Raylib.Color.create(22, 23, 26, 255);
  var fg = Raylib.Color.create(250, 253, 255, 255);
  var hg = Raylib.Color.create(255, 38, 116, 255);
  var border = Raylib.Color.create(67, 0, 103, 255);
  function phone() {
    if(startPlay) {
    Raylib.drawTexture(Assets.images["content/ui.ase"].spritesheet, 386, 265, Raylib.Colors.WHITE);
    text(enemyNames[enemy],406, 270, 8, hg);
    var x = 392;
    var y = 284;
    text('Profession: ${enemyProfession[enemy]}', x, y, 8, fg);
    y+=8;
    text('Debt: ', x, y, 8, fg);
    var asdad = Raylib.measureTextEx(font, "Debt: ", 8, 0);
    text('${512-enemyAmount}/512', x+asdad.x, y, 8, fg);
    y+=12;
    text('"Collect" the money from him', x, y, 8, fg);

    // text('Your debt is', 396, 350, 8, fg);
    // var asdad = Raylib.measureTextEx(font, "your debt is ", 8, 0);
    // text('${player.debt}', 396+asdad.x, 350, 8, hg);
    }
  }

  var lineTimer = 20.;
  function panel() {
    if(showstart) {
      var px = 5;
      var py = 265;
      var rec = Raylib.Rectangle.create(px, py, 470, 100);
      Raylib.drawRectangleRec(rec, bgc);
      Raylib.drawRectangleLinesEx(rec, 1, hg);

      px += 4;
      py += 4;
      text("CEO", px, py, 8, hg);
      py += 10;      
      if(enemies.length == 3) {
      text("*ahem* YOU can claim YOUR insurance by eliminating competition and DO IT QUICK", px, py, 8, fg);
      py+=8;
      text("they might run idk :DDD", px, py, 8, fg);
      py += 8;
      text("Press [SPACE] to start now!", px, py, 8, fg);
      } else if(enemies.length == 2) {
        text("Alright that was a good one, you need to get better at this though ;)", px, py, 8, fg);
        py+=8;
        text("the next person is VERY smart and u might dieeee", px, py, 8, fg);
        py += 8;
        text("Press [SPACE] to start now!", px, py, 8, fg);
      } else if(enemies.length == 1) {
        text("Damn... alright. you wont get past her though", px, py, 8, fg);
        py+=8;
        text("cya at the start again", px, py, 8, fg);
        py += 8;
        text("Press [SPACE] to start now!", px, py, 8, fg);
      } else if(enemies.length == 0) {
        text("...", px, py, 8, fg);
        py+=8;
        text("i guess you've done it", px, py, 8, fg);
        py += 8;
        text("*sigh* Press [SPACE] to recieve your money...", px, py, 8, fg);
        if(Raylib.isKeyPressed(Keys.SPACE)) gameOver = true;
      } else {
        text("You can always try again here", px, py, 8, fg);
        py+=8;
        text("or leave depends on your sanity", px, py, 8, fg);
        py += 8;
        text("Press [SPACE] to start now!", px, py, 8, fg);
      }
    
      if(Raylib.isKeyPressed(Keys.SPACE) && enemies.length > 0) {startPlay = true; showstart = false; curtain = 360;}
    }

    if(startPlay) {
      Raylib.setMusicVolume(ambient, 3);

      var px = 5;
      var py = 265;
      var rec = Raylib.Rectangle.create(px, py, 375, 100);
      Raylib.drawRectangleRec(rec, bgc);
      Raylib.drawRectangleLinesEx(rec, 1, hg);

      px+=4;
      py+=4;
      text("CONTRACT", px, py, 8, hg);
      var asdasd = Raylib.measureTextEx(font, "CONTRACT", 8, 0);
      var spl = enemyFiles[enemy].split(".");
      if(currentCharPlayer == spl[currentLinePlayer].length) {
        if(canAttack) text("press [enter] to go to attack", px+asdasd.x+2, py, 8, fg);
        else text("stay in the box!!!", px+asdasd.x+2, py, 8, fg);
        if(Raylib.isKeyPressed(Keys.ENTER)) {currentLinePlayer++;currentCharPlayer = 0;enemyAmount -= 64;lineTimer=20;enemies[enemy].newhit();player.shoot();changeHitDialogue = true;}
      } else
        if(!canAttack) text("STAY IN THE BOX to type!!", px+asdasd.x+2, py, 8, fg);
        else text("start typing the text below!!!", px+asdasd.x+2, py, 8, fg);
      py += 10;

      // Raylib.drawRectangle(px, py, Std.int(rec.width-8 * ((enemyAmount/512))), 4, fg);
      // Timer.delay(()->{lineTimer--;}, 1000);
      if(curtain == 0) lineTimer -= Raylib.getFrameTime() * mult;
      // trace(lineTimer);
      Raylib.drawRectangle(px, py, Std.int((rec.width-8) * (lineTimer/20)), 4, enemies[enemy].spr.tint);
      py += 6;

      // line logic
      trace(enemies);
      trace(enemyFiles);
      var spl = enemyFiles[0].split(".");
      spl[currentLinePlayer] = StringTools.ltrim(spl[currentLinePlayer]);
      var t = Raylib.measureTextEx(font, spl[currentLinePlayer], 8, 0);
      Raylib.drawRectangle(px, py, Std.int(t.x)+2, 8+4, hg);
      px += 2;
      py += 4;
      text(spl[currentLinePlayer], px, py, 8, bgc);
      text(spl[currentLinePlayer].substring(0, currentCharPlayer), px, py, 8, fg);
      if(spl[currentLinePlayer].charAt(currentCharPlayer) == String.fromCharCode(Raylib.getCharPressed()) && canAttack) {currentCharPlayer++;cameraShake=true;}
      py += 32;

      // spl[currentLineEnemy] = StringTools.ltrim(spl[currentLineEnemy]);
      // text(spl[currentLineEnemy], px, py, 8, border);
      // text(spl[currentLineEnemy].substring(0, currentCharEnemy), px, py, 8, fg);
      // Timer.delay(()->{currentCharEnemy++;}, 500);
      // if(spl[currentLinePlayer].charAt(currentCharPlayer) == String.fromCharCode(Raylib.getCharPressed())) currentCharPlayer++;

      if(Raylib.isKeyPressed(Raylib.Keys.F9)) enemyAmount = 0;
      if(enemyAmount == 0) {
        startPlay = false;
        Raylib.pauseMusicStream(music);
        enemies.remove(enemies[enemy]);
        enemyAmount = 512;
        enemyProfession.remove(enemyProfession[0]);
        enemyDialogues.remove(enemyDialogues[0]);
        enemyNames.remove(enemyNames[0]);
        enemyFiles.remove(enemyNames[0]);
        lineTimer = 20;
        killcount++;
        currentLinePlayer = 0;
        // enemy++;
      }
    }
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