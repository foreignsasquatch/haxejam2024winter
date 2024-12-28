package engine;

import Raylib.RlImage;
import ase.chunks.TagsChunk;
import Raylib.Colors;
import Raylib.Vector2;
import haxe.ds.Vector;
import Raylib.Rectangle;
import Raylib.Image;
import cpp.NativeArray;
import cpp.Pointer;
import haxe.io.Bytes;
import ase.Frame;
import Raylib.Texture;
import sys.io.File;
import ase.Ase;

typedef AsepriteLayer = {
    texture:Texture,
    layerID:Int,
    frameID:Int
}

@:structInit
class Tag {
  public var name(default, null):String;
  public var startFrame(default, null):Int;
  public var endFrame(default, null):Int;
  public var animationDirection(default, null):Int;

  public static function fromChunk(chunk:ase.chunks.TagsChunk.Tag):Tag {
    return {
      name: chunk.tagName,
      startFrame: chunk.fromFrame,
      endFrame: chunk.toFrame,
      animationDirection: chunk.animDirection
    }
  }
}

class Aseprite {
    public var ase:Ase;
    public var width:Int;
    public var height:Int;

    public var intermediateLayers:Array<AsepriteLayer> = [];
    public var intermediateFrames:Map<Int, Texture> = [];
    public var spritesheet:Texture;

    public var tags:Map<String, Tag> = [];
    public var duration:Map<Int, Float> = [];

    public function new(file:String) {
        ase = Ase.fromBytes(File.getBytes(file));
        width = ase.width;
        height = ase.width;

         // generate intermediate layers
         for(f in 0...ase.frames.length) {
          var frame = ase.frames[f];
          for(layer in 0...ase.layers.length) {
                if(ase.layers[layer].visible == true) {
                    var t = genTexture(layer, frame);
                    intermediateLayers.push({texture: t, layerID: layer, frameID: f});
                }
          }
      }

      for(f in 0...ase.frames.length) {
          var rt = Raylib.loadRenderTexture(ase.width, ase.height);
          for(il in intermediateLayers) {
              if(il.frameID == f) {
                  var sourceRec = Rectangle.create(0, 0, ase.frames[f].cel(il.layerID).width, ase.frames[f].cel(il.layerID).height);

                  Raylib.beginTextureMode(rt);
                  Raylib.drawTexturePro(il.texture, sourceRec, Raylib.Rectangle.create(ase.frames[f].cel(il.layerID).xPosition, ase.frames[f].cel(il.layerID).yPosition, ase.frames[f].cel(il.layerID).width, ase.frames[f].cel(il.layerID).height), Raylib.Vector2.zero(), 0, Raylib.Colors.WHITE);
                  Raylib.endTextureMode();
              }
          }
          var it:RlImage = Raylib.loadImageFromTexture(rt.texture);
          Raylib.imageFlipVertical(cast(it));
          var ft = Raylib.loadTextureFromImage(it);
          intermediateFrames.set(f, ft);
          Raylib.unloadRenderTexture(rt);
      }

      // generate spritesheet
      var sprt = Raylib.loadRenderTexture(ase.width * ase.frames.length, ase.height);
      var noi = 0;
      for(r in 0...ase.frames.length) {
          var i = intermediateFrames[r];
          Raylib.beginTextureMode(sprt);
          Raylib.drawTexture(i, 0 + (i.width * noi), 0, Raylib.Colors.WHITE);
          Raylib.endTextureMode();
          noi++;
      }
      var it:RlImage = Raylib.loadImageFromTexture(sprt.texture);
      Raylib.imageFlipVertical(cast(it));
      spritesheet = Raylib.loadTextureFromImage(it);
      Raylib.unloadRenderTexture(sprt);

      // delete all intermediates cause who needs them now
      for(i in intermediateFrames) {
          Raylib.unloadTexture(i);
      }
      intermediateFrames.clear();

      for(i in intermediateLayers) {
          Raylib.unloadTexture(i.texture);
          intermediateLayers.remove(i);
      }

      // get tags and duration
      for(frame in ase.frames) {
          for(chunk in frame.chunks) {
              switch (chunk.header.type) {
                  case TAGS:
                      var frameTags:TagsChunk = cast chunk;

                      for(frameTagData in frameTags.tags) {
                          var animationTag = Tag.fromChunk(frameTagData);

                          if(tags.exists(frameTagData.tagName)) {
                              throw 'ERROR: This file already contains a tag named ${frameTagData.tagName}';
                          } else  {
                              tags[frameTagData.tagName] = animationTag;
                          }
                      }
                  case _:
              }
          }

          duration[ase.frames.indexOf(frame)] = frame.duration;
      }
    }

    public function genTexture(layer:Int, frame:Frame):Texture {
      var layerIndex:Int = layer;
      var celWidth:Int = frame.cel(layer).width;
      var celHeight:Int = frame.cel(layer).height;
      var celPixelData:haxe.io.Bytes = frame.cel(layerIndex).pixelData;
      var celDataPointer:cpp.Pointer<cpp.Void> = cpp.NativeArray.address(celPixelData.getData(), 0).reinterpret();
      var celImage = Raylib.Image.create(celDataPointer.raw, celWidth, celHeight, 1, Raylib.PixelFormat.UNCOMPRESSED_R8G8B8A8);
      var celTexture = Raylib.loadTextureFromImage(celImage); 
      return celTexture;
    }

    public function unload() {
        Raylib.unloadTexture(spritesheet);
    }
}