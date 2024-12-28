package engine;

import kui.impl.Base;
import kui.Component;
import Raylib.Vector2;
import engine.RoomSerializables.EntityData;
import sys.io.File;
import sys.FileSystem;
import kui.KumoUI;
import Raylib.Texture;
import Raylib;

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

function vscale(v:Vector2, s:Float):Vector2 {
  return Vector2.create(v.x * s, v.y * s);
}

function vadd(v:Vector2, s:Vector2):Vector2 {
  return Vector2.create(v.x + s.x, v.y + s.y);
}

class TilePicker extends Component {
  public static function use(isUsingCamera:Bool, currentRoomCollection:RoomCollection, selectedRoom:Room, selectedTile:Int): Int {KumoUI.addComponent(TilePicker, {isUsingCamera: isUsingCamera, currentRoomCollection: currentRoomCollection, selectedRoom: selectedRoom, selectedTile: selectedTile}); return selectedTile;}

  var currentRoomCollection:RoomCollection;
  var isUsingCamera:Bool;
  var selectedRoom:Room;
  var selectedTile:Int;

  override function onDataUpdate(data: Dynamic): Dynamic {
    isUsingCamera = data.isUsingCamera;
    currentRoomCollection = data.currentRoomCollection;
    selectedRoom = data.selectedRoom;
    selectedTile = data.selectedTile;
    return null;
}

  override function onRender(impl:Base) {
 
    }

    override function onLayoutUpdate(impl: Base) {
      useLayoutPosition();
      // setSize(targetWidth, targetHeight);
      useBoundsClipRect();
      submitLayoutRequest();
  }
}


class Editor implements Module {
  public static var active = false;
  public static var currentRoomCollection:RoomCollection;
  public static var currentRoomToPlay:Room;
  public static var setCurrentRoom = false;

  var cam:Camera2D;
  var checkerboard:Texture;

  // ui locks
  // var isBarActive = false;
  // var isPanelActive = false;
  var isUiActive = false;
  var isUsingCamera = false;
  var tileselect = false;
  // var isEntityPanelActive=false;

  var createroommode = false;

  // scene stuff
  var selectedRoom:Room = null;
  var selectedLayer:String = 'solids';
  var selectedTile:Int = 1; // default
  var canEdit = false;

  var entityList:Array<String> = [];
  var selectedEntity:EntityData = null;
  var entityToPlace:String = null;

  public function new() {
    var img = Raylib.genImageChecked(512, 512, 16, 16, Raylib.Colors.DARKGRAY, Raylib.Color.create(50, 50, 50, 255));
    checkerboard = Raylib.loadTextureFromImage(img);
    Raylib.unloadImage(img);

    cam = Camera2D.create(Vector2.zero(), Vector2.zero());
    cam.zoom = 2;
  }

  public function update() {
    if(KumoUI.lastHovered != null || tileselect) isUiActive = true;
    else isUiActive = false;

    if(!isUiActive) handleCam();
    var mx = Raylib.getMouseX();
    var my = Raylib.getMouseY();
    var mpos = Raylib.getScreenToWorld2D(Vector2.create(mx, my), cam);

    // room selection
    if(selectedRoom == null) {
      if(currentRoomCollection == null || isUsingCamera ) return;

      for(room in currentRoomCollection.rooms) {
        if(Raylib.isMouseButtonDown(MouseButton.LEFT) && Raylib.checkCollisionPointRec(mpos, Raylib.Rectangle.create(room.x, room.y, room.width, room.height))) selectedRoom = room;
      }
    } else {
      if(Raylib.isKeyPressed(Raylib.Keys.ESCAPE)) {
        if(selectedEntity!=null) {selectedEntity=null;return;}
        // if(createEntityMode) {createEntityMode=false;return;}

        if(canEdit) {
            canEdit = false;
        } else {
            selectedRoom = null;
        }
      }
    }

    // placing/removing tiles
    if(selectedRoom != null) {
      var mpos = Raylib.getScreenToWorld2D(Raylib.getMousePosition(), cam);
      if(Raylib.checkCollisionPointRec(mpos, Raylib.Rectangle.create(selectedRoom.x, selectedRoom.y, selectedRoom.width, selectedRoom.height)) && !isUsingCamera && canEdit && !isUiActive) {
          var mx = (mpos.x - selectedRoom.x);
          var my = (mpos.y - selectedRoom.y);
          var x = Std.int(mx / currentRoomCollection.gridsize);
          var y = Std.int(my / currentRoomCollection.gridsize);
          if(Raylib.isMouseButtonDown(Raylib.MouseButton.LEFT)) selectedRoom.set(x, y, selectedTile, selectedLayer);
          if(Raylib.isMouseButtonDown(Raylib.MouseButton.RIGHT)) selectedRoom.remove(x, y, selectedLayer);
      }
  }

    // mouse cursor and room creation
    if(createroommode) {
      Raylib.setMouseCursor(MouseCursor.POINTING_HAND);
    } else {
      Raylib.setMouseCursor(MouseCursor.ARROW);
    }

    if(createroommode) {
      if(Raylib.isMouseButtonReleased(MouseButton.LEFT) && !isUsingCamera) {
        createNewRoom();
        createroommode = false;
      }
    }
  }

  function handleCam() {
      // camera controls
      cam.zoom = cam.zoom + Raylib.getMouseWheelMove() * 0.1;
      if(cam.zoom < 0.125) cam.zoom = 0.125;

      if(Raylib.isKeyDown(Raylib.Keys.SPACE) && Raylib.isMouseButtonDown(Raylib.MouseButton.LEFT)) {
          var delta = vscale(Raylib.getMouseDelta(), -1.0 / cam.zoom);

          // set the camera target to follow the player
          cam.target = vadd(cam.target, delta);
      }

      if(Raylib.isKeyDown(Raylib.Keys.SPACE)) isUsingCamera = true;
      else isUsingCamera = false;
  }

  var mouseScaleReady= false;
  var mouseScaleMode = false;
  public function draw() {

    var mpos = Raylib.getScreenToWorld2D(Raylib.getMousePosition(), cam);

    // draw worldspace stuff here
    Raylib.beginMode2D(cam);
    var rec = Raylib.Rectangle.create(cam.target.x, cam.target.y, Raylib.getScreenWidth() / cam.zoom, Raylib.getScreenHeight() / cam.zoom);
    Raylib.drawTexturePro(checkerboard, rec, rec, Vector2.zero(), 0, Raylib.Colors.WHITE);

    if(currentRoomCollection != null) {
    // drawing room tiles
   for(room in currentRoomCollection.rooms) {
     Raylib.drawRectangle(room.x, room.y, room.width, room.height, Raylib.Colors.BLACK);
     room.renderBackground();
     room.renderSolids();
     room.renderForeground();
     // drawing room entities
     for(entity in room.entities) {
         if(Assets.entities[entity.id]['sprite'] != null)
             Raylib.drawTextureRec(Assets.images[Assets.entities[entity.id]['sprite']].spritesheet, Rectangle.create(0, 0, Assets.images[Assets.entities[entity.id]['sprite']].width, Assets.images[Assets.entities[entity.id]['sprite']].height), Raylib.Vector2.create(entity.x, entity.y), Colors.WHITE);
         else Raylib.drawRectangleLines(Std.int(entity.x), Std.int(entity.y), 32,  32, Raylib.Colors.RED);
     }
     Raylib.drawRectangleLinesEx(Raylib.Rectangle.create(room.x, room.y, room.width, room.height), 2, Raylib.Colors.WHITE);
     }
     
     // drawing room border and grid
     if(selectedRoom != null) {
         grid(selectedRoom.x, selectedRoom.y, selectedRoom.width, selectedRoom.height, currentRoomCollection.gridsize, Raylib.Colors.GRAY);
         // changinrg room position
         if(Raylib.isKeyDown(Raylib.Keys.LEFT_CONTROL) && Raylib.isMouseButtonDown(Raylib.MouseButton.LEFT)) {
             var x = Std.int(mpos.x / currentRoomCollection.gridsize) * currentRoomCollection.gridsize;
             var y = Std.int(mpos.y / currentRoomCollection.gridsize) * currentRoomCollection.gridsize;
             selectedRoom.x = Std.int(x);
             selectedRoom.y = Std.int(y);
         }
     }
    }

    if(selectedRoom != null && !canEdit) {
      var rec = Rectangle.create(selectedRoom.x, selectedRoom.y, selectedRoom.width, selectedRoom.height);

      if (Raylib.checkCollisionPointRec(mpos, Raylib.Rectangle.create(rec.x + rec.width - 12, rec.y + rec.height - 12, 12, 12)))
      {
          mouseScaleReady = true;
          if (Raylib.isMouseButtonPressed(MouseButton.LEFT)) mouseScaleMode = true;
      }
      else mouseScaleReady = false;

      if (mouseScaleMode)
      {
          mouseScaleReady = true;
          var x = Std.int(mpos.x / currentRoomCollection.gridsize) * currentRoomCollection.gridsize;
          var y = Std.int(mpos.y / currentRoomCollection.gridsize) * currentRoomCollection.gridsize;
          rec.width = (x - rec.x);
          rec.height = (y - rec.y);
          if (Raylib.isMouseButtonReleased(MouseButton.LEFT)) mouseScaleMode = false;
      }

      selectedRoom.width = Std.int(rec.width);
      selectedRoom.height = Std.int(rec.height);

      Raylib.drawTriangle(Vector2.create(rec.x + rec.width - 12, rec.y + rec.height),
              Vector2.create(rec.x + rec.width, rec.y + rec.height),
              Vector2.create(rec.x + rec.width, rec.y + rec.height - 12), Raylib.Colors.WHITE);
  }

  // drawing current selected tile
  if(canEdit && selectedRoom != null && selectedLayer != 'Entities') {
      // draw mouse tile pick
      var tpx = Std.int(mpos.x / currentRoomCollection.gridsize);
      var tpy = Std.int(mpos.y / currentRoomCollection.gridsize);
      Raylib.drawTextureRec(Assets.images[selectedRoom.tileset].spritesheet, selectedRoom.parent.tilesetMap[selectedRoom.tileset][selectedTile], Raylib.Vector2.create(tpx * currentRoomCollection.gridsize, tpy * currentRoomCollection.gridsize), Colors.LIGHTGRAY);
  }

    Raylib.endMode2D();
  }

  var nnnnnnnnn = "-";
  public function ui() {
    // default window
    if(currentRoomCollection != null) nnnnnnnnn = currentRoomCollection.file;
    KumoUI.beginWindow(nnnnnnnnn, "default_window", null, null, 400, 600);
    defaultPanel();
    KumoUI.endWindow();
  
    if(canEdit) editPanel();
  }

  function defaultPanel() {
    if(currentRoomCollection == null) {
      KumoUI.text("No RoomCollection loaded");
      var name = KumoUI.inputText("file_input", "", "file path");
      KumoUI.sameLine();
      var l = KumoUI.button("create");
      if(l) {
        createRoomCollection(name);
        Assets.loadScene(name);
      }

      // selection from loaded room cllectins
      if(KumoUI.beginTreeNode('Loaded RoomCollections')) {
        for(r in Assets.rooms) if(KumoUI.button(r.file)) currentRoomCollection = r;
      }
      KumoUI.endTreeNode();
    } else {
      if(KumoUI.button("Save")) currentRoomCollection.serialize();
      KumoUI.separator();
      currentRoomCollection.gridsize = KumoUI.inputInt("grdiszi", "gridsize", "", null, null, currentRoomCollection.gridsize);
      currentRoomCollection.defaultTileset = KumoUI.inputText("defaultTleet", "tileset", "", currentRoomCollection.defaultTileset);
      KumoUI.separator();

      if(selectedRoom == null) KumoUI.text("No room selected");
      else {
        KumoUI.text('Room ${selectedRoom.id}');
        selectedRoom.width = KumoUI.inputInt("selectedRoomW", "width", "", null, null, selectedRoom.width);
        selectedRoom.height = KumoUI.inputInt("selectedRoomH", "height", "", null, null, selectedRoom.height);
      }
      if(KumoUI.button("Create Room")) {
        createroommode = true;
      }
      KumoUI.sameLine();
      if(KumoUI.button("Delete Room")) deleteSelectedRoom();
      KumoUI.sameLine();
      if(KumoUI.button("Edit Room")) if(selectedRoom!=null) canEdit = true;

      if(canEdit) {
      KumoUI.separator();
      KumoUI.text("Edit");
      if(KumoUI.beginTreeNode("Layers")) {
        KumoUI.text('Current layer: $selectedLayer');
        if(KumoUI.button("Solids")) selectedLayer = "solids";
        KumoUI.sameLine();
        if(KumoUI.button("Background")) selectedLayer = "background";
        KumoUI.sameLine();
        if(KumoUI.button("Foreground")) selectedLayer = "foreground";
      }
      KumoUI.endTreeNode();
      KumoUI.button("Entities");
      }
    }
  }

  var tileCam = Camera2D.create(Raylib.Vector2.zero(), Vector2.zero(), 0, 2);
  function editPanel() {
    if(Raylib.isKeyPressed(Raylib.Keys.TAB)) tileselect = !tileselect;
    if(tileselect) isUiActive = true;
    if(tileselect) {
    // Raylib.drawRectangle(Std.int(, Raylib.Color.create(0, 0, 0, 255));
               // draw rectangle to display the tileset
               var rec = Raylib.Rectangle.create(1600/2-300, 900/2-300, 600, 600);
               Raylib.drawRectangle(0, 0, 1600, 900, Raylib.Color.create(0, 0, 0, 200));
               Raylib.drawRectangleRec(rec, Raylib.Colors.BLACK);
               // Im.rectBorder(rec.x, rec.y, rec.width, rec.height);
               Raylib.drawRectangleLinesEx(rec, 2, Raylib.Colors.GRAY);
       
               // camera controls
               if(Raylib.checkCollisionPointRec(Raylib.getMousePosition(), rec)) {
                   tileCam.zoom = tileCam.zoom + Raylib.getMouseWheelMove() * 0.1;
                   if(tileCam.zoom < 0.125) tileCam.zoom = 0.125;
       
                   if(Raylib.isKeyDown(Raylib.Keys.SPACE) && Raylib.isMouseButtonDown(Raylib.MouseButton.LEFT)) {
                       var delta = vscale(Raylib.getMouseDelta(), -1.0 / tileCam.zoom);
       
                       // set the camera target to follow the player
                       tileCam.target = vadd(tileCam.target, delta);
                   }
       
                   if(Raylib.isKeyDown(Raylib.Keys.SPACE)) isUsingCamera = true;
                   else isUsingCamera = false;
               }
       
               var mpos = Raylib.getScreenToWorld2D(Raylib.getMousePosition(), tileCam);
               // draw mouse tile pick
               var tpx = Std.int(mpos.x / currentRoomCollection.gridsize);
               var tpy = Std.int(mpos.y / currentRoomCollection.gridsize);
       
               // SCISSOR BEGIN
               Raylib.beginScissorMode(Std.int(rec.x), Std.int(rec.y), Std.int(rec.width), Std.int(rec.height));
       
               Raylib.beginMode2D(tileCam);
               var images = Assets.images[selectedRoom.tileset];
               Raylib.drawTexture(Assets.images[selectedRoom.tileset].spritesheet, Std.int(0), Std.int(0), Raylib.Colors.WHITE);
       
               // draw grid
               grid(0, 0, images.width, images.height, currentRoomCollection.gridsize, Raylib.Colors.GRAY);
               Raylib.drawRectangleLines(0, 0, images.width, images.height, Raylib.Colors.GRAY);
       
               Raylib.drawRectangleLines(tpx * currentRoomCollection.gridsize, tpy * currentRoomCollection.gridsize, currentRoomCollection.gridsize, currentRoomCollection.gridsize, Raylib.Colors.WHITE);
       
               if(Raylib.checkCollisionPointRec(Raylib.getMousePosition(), rec)) {
                   // SELECTING THE TILE
                   if(tpx >= 0 && tpx <= images.width / currentRoomCollection.gridsize && tpy <= images.height / currentRoomCollection.gridsize && tpy >= 0 && Raylib.isMouseButtonPressed(Raylib.MouseButton.LEFT) && !Raylib.isKeyDown(SPACE)) {
                       selectedTile = Std.int(tpy * (images.width/currentRoomCollection.gridsize) + (tpx)) + 1;
                   }
               }
       
               // draw selected tile
               var sx = Std.int(Std.int((selectedTile-1) % Std.int(images.width/currentRoomCollection.gridsize)) * currentRoomCollection.gridsize);
               var sy = Std.int(Std.int((selectedTile-1) / Std.int(images.height/currentRoomCollection.gridsize)) * currentRoomCollection.gridsize);
               Raylib.drawRectangleLines(sx, sy, Std.int(currentRoomCollection.gridsize), Std.int(currentRoomCollection.gridsize), Raylib.Colors.GREEN);
       
               Raylib.endMode2D();
       
               Raylib.endScissorMode();
               // SCISSOR END
              }
  }

  function createRoomCollection(name:String) {
    File.saveContent(name, 
    '{
      "rooms": [],
      "gridsize": 32,
      "defaultTileset": ""
    }');
  }

  function createNewRoom() {
    var mx = Raylib.getMouseX();
    var my = Raylib.getMouseY();
    var mpos = Raylib.getScreenToWorld2D(Vector2.create(mx, my), cam);

    var room:Room = {
        x: Std.int(mpos.x),
        y: Std.int(mpos.y),
        width: 256,
        height: 256,
        foreground: [],
        solids: [],
        background: [],
        entities: [],
        id: -1,
        tileset: currentRoomCollection.defaultTileset,
        parent: currentRoomCollection,
        bgImgs: []
    }

    room.id = currentRoomCollection.rooms.length;
    currentRoomCollection.add(room);
}

function deleteSelectedRoom() {
    if(selectedRoom!=null) currentRoomCollection.remove(selectedRoom);
    selectedRoom = null;
}

// function createNewEntity() {
//     var mpos = Raylib.getScreenToWorld2D(Raylib.getMousePosition(), cam);
//     var x = mpos.x;
//     var y = mpos.y;

//     if (Raylib.isKeyDown(Raylib.Keys.LEFT_SHIFT)) {
//         if(Raylib.isKeyDown(Raylib.Keys.X)) x = Std.int( (Std.int(mpos.x / currentRoomCollection.gridsize) * currentRoomCollection.gridsize) );
//         if(Raylib.isKeyDown(Raylib.Keys.Z)) y = Std.int( (Std.int(mpos.y / currentRoomCollection.gridsize) * currentRoomCollection.gridsize) );
//     }

//     var entityData:EntityData = {
//         x: Std.int(x),
//         y: Std.int(y),
//         id: entityToPlace,
//     }

//     selectedRoom.entities.push(entityData);
// }
}