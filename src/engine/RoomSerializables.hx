package engine;

typedef RoomCollectionData = {
  rooms:Array<RoomData>,
  defaultTileset:String,
  gridsize:Int,
}

typedef RoomData = {
  id:Int,
  x:Int,
  y:Int,
  width:Int,
  height:Int,
  solids:Array<Int>,
  foreground:Array<Int>,
  background:Array<Int>,
  tileset:String,
  entities:Array<EntityData>,
  bgImgs:Array<String>
}

typedef EntityData = {
  id:String,
  x:Float,
  y:Float,
}