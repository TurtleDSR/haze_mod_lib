import lib.haze_mod_lib as modlib
try: 
  context = modlib.ModLib("test/static/sandbox/")

  mod = modlib.Mod("test/static/mods/test.hazemod")
  properties: modlib.ModProperties = mod.get_properties()

  if(properties.author != "TurtleDSR"):
    raise Exception("invalid properties")

  context.queue_mod(mod)
  context.install_mods()

except Exception as err:
  print("error:", err)

else:
  print("success")
