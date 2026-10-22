package test.java;

import com.turtledsr.hazemodlib.*;

public class Main {
  public static void main(String[] args) {
    try {
      ModLib context = new ModLib("../../../test/static/sandbox/");
      Mod mod = new Mod("../../../test/static/mods/test.hazemod");

      context.queueMod(mod);
      context.installMods();

      System.err.println("Success!");
    } catch(Exception e) {
      System.err.println("Error: " + e.getLocalizedMessage());
    }
  }
}
