## Operators: (parameters are case sensitive)
* @open \<file> - Opens a file, all operations will be done in this file until a new one is opened.

* @import \<file> - Adds an import of the spcified file to the currently opened file.

* @patch \<class> \<type> \<target> - Replaces a target function, enum or property within the specified class found within the currently opened file. type can be either property, enum, or function. @end must be used to define where the patch code scope ends. Class can be either a specified class/struct or auto (finds first instance under the target identifier).

* @add \<class> \<type> - Adds a target function, enum, or property within the specified class found within the currently opened file. type can be either property, enum, or function. @end must be used to define where the added code scope ends. Class can be either a class/struct (not generally good practice to add functions to structs and adding a UFUNCTION will result in error) or auto (will add to the first found class) or global (added to the global scope).

* @end - Closes the scope of the current @patch or @add operation.

* @// - Comment that will be stripped from the output file. Does not need a space after the slashes.

## Examples:
* ### @open: 
  ```cpp
  @open Rice/Debug/DebugInfoWidget.as
  ```
* ### @patch:
  * #### function:
    ```cpp
    @open Rice/Debug/DebugInfoWidget.as
    @patch auto function UpdateText //patch first UpdateText function found in file
      void UpdateText() //makes the current loaded progress point appear in the bottom right corner
      {
        FString Text;
        Text += Progress::DebugGetActiveProgressPoint();

        Text += "\n"; 
        TextWidget.SetText(FText::FromString(Text));
      }
    @end
    ```
  * #### property:
    ```cpp
    @open Cake/LevelSpecific/Shed/Vacuum/VacuumBoss/VacuumBoss.as
    @patch AVacuumBoss property SlamAmount //patch property in class AVacuumBoss
      int SlamAmount = 12; //double slam amount to 12
    @end
    ```
  * #### enum:
    ```cpp
    @open Cake/LevelSpecific/Shed/Vacuum/VacuumBoss/VacuumBoss.as
    @patch global enum EVacuumBossAttackMode //patch enum found globally in VacuumBoss.as
      enum EVacuumBossAttackMode
      {
        Debris,
        Slam,
      	DoubleSlam,
        DebrisSlam,
        Minefield,
        Bombs,
        ModdedFinalPhase, //add new phase to boss
      }
    @end
    ```
* ### @add:
  * #### function:
    ```cpp
    @open Vino/Character/PlayerCharacter.as
    @add auto function //speedtools show volumes dev menu button, auto adds it to the first class in file
      UFUNCTION(DevFunction)
      void Show_Volumes()
      {
        System::ExecuteConsoleCommand("show volumes");
      }
    @end
    ```
  * #### property:
    ```cpp
    @add auto property
      UPROPERTY(CustomMod)
      int custom_value = 3;
    @end
    ```
* ### @import:
  ```cpp
  @import Mods.MyMod.FunctionLibrary.as //imports a library to the currently opened file to use in a patched function.
  ```