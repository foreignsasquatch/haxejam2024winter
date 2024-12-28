package engine;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import haxe.Timer;
import haxe.DynamicAccess;

typedef AssetLibrary = {
    images:Array<String>,
    rooms:Array<String>,
    entities:String
}

class Assets {
    public static var images:Map<String, Aseprite> = [];
    public static var rooms:Map<String, RoomCollection> = [];
    public static var entities:DynamicAccess<DynamicAccess<Dynamic>>;

    public static function load(file:String) {
        var start = Timer.stamp();
        var lib:AssetLibrary = Json.parse(File.getContent(file));

        for(image in lib.images) loadImage(image);
        for(room in lib.rooms) loadScene(room);
        entities = Json.parse(sys.io.File.getContent(lib.entities));

        var totalLoadTime = Std.string(Timer.stamp() - start);
        totalLoadTime = totalLoadTime.substring(0, 4);
        trace('All assets have been loaded in ${totalLoadTime}s');
    }

    public static function loadImage(file:String) {
        if(!FileSystem.exists(file)) trace('Asset $file does not exist.');
        else images.set(file, new Aseprite(file));
    }

    public static function loadScene(file:String) {
      if(!FileSystem.exists(file)) trace('Asset $file does not exist.');
      else rooms.set(file, new RoomCollection(file));
  }

    public static function unload() {
        for(image in images) image.unload();
        trace("All assets have been unloaded.");
    }
}