class WebAssetPath {
  public static macro function setAssetPath(folder:String) {
    #if wasm
    haxe.macro.Compiler.define('ASSET_PATH', '${sys.FileSystem.absolutePath(folder)}@$folder');
    #end
    return null;
  }
}