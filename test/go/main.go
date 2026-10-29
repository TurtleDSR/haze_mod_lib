package main

import (
	"hazemodlib"
	"log"
)

func main() {
	context, err := hazemodlib.NewModLib("../static/sandbox/")
	if err != nil {
		log.Fatal(err.Error())
	}

	mod, err := hazemodlib.NewMod("../static/mods/test.hazemod")
	if err != nil {
		log.Fatal(err.Error())
	}

	properties, err := mod.GetProperties()
	if err != nil {
		log.Fatal(err.Error())
	}

	if(properties.Format() != hazemodlib.Hazemod) {
		log.Fatalf("invalid properties")
	}

	if(len(properties.Dependencies()) != 0) {
		log.Fatalf("invalid properties")
	}

	err = context.QueueMod(mod)
	if err != nil {
		log.Fatal(err.Error())
	}

	err = context.InstallMods()
	if err != nil {
		log.Fatal(err.Error())
	}

	log.Print("Success!")
}