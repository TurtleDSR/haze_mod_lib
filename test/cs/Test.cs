using Com.Turtledsr.HazeModLib;

class Test {
  static void Main() {
    try {
      ModLib Context = new("test/static/sandbox");
      Mod TestMod = new("test/static/mods/test.hazemod");
      Context.QueueMod(TestMod);
      Context.InstallMods();

      Console.WriteLine("Success");
    } catch(Exception e) {
      Console.WriteLine("ERROR: " + e.ToString());
    }
  }
}