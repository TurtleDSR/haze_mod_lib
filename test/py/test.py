import lib.haze_mod_lib as modlib
try: 
  context = modlib.ModLib("test/static/sandbox/")

  mod = modlib.Mod("test/static/mods/test.hazemod")
  properties: modlib.ModProperties = mod.get_properties()

  if(properties.format != modlib.hazemod):
    raise Exception("invalid properties")

  if(len(properties.get_dependencies()) != 0):
    raise Exception("invalid properties")

  context.queue_mod(mod)
  context.install_mods()

except Exception as err:
  print("error:", err)

else:
  print("success")
