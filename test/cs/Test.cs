using Com.Turtledsr.HazeModLib;

class Test {
  static void Main() {
    try {
      ModLib context = new("test/static/sandbox");
      Mod mod = new("test/static/mods/test.hazemod");

      ModProperties properties = mod.GetProperties();
      if(properties.format != ModFormat.hazemod) {
        throw new Exception("Invalid Properties");
      }

      if(properties.GetDependencies().Count != 0) {
        throw new Exception("Invalid Properties");
      }

      context.QueueMod(mod);
      context.InstallMods();

      Console.WriteLine("Success");
    } catch(Exception e) {
      Console.WriteLine("ERROR: " + e.ToString());
    }
  }
}