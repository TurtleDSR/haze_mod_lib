package hazemodlib

/*
#cgo LDFLAGS: -L${SRCDIR} -lhaze_mod_lib_go -Wl,-rpath,'$ORIGIN'
#cgo CFLAGS: -I${SRCDIR}
#include "haze_mod_lib.h"
#include <stdlib.h>
*/
import "C"

import (
	"errors"
	"runtime"
	"unsafe"
)

// Mod format enum
type ModFormat int
// ModFormat.Hazemod
const Hazemod ModFormat = C.hazemod
// ModFormat.Zip
const Zip ModFormat = C.zip

// Handle for mod injection
type ModLib struct {
	ptr *C.struct_modlib_t
}

// Handle for a mod instance
type Mod struct {
	ptr *C.struct_mod_t
}

// Handle for a mod properties
type ModProperties struct {
	ptr *C.struct_modproperties_t
}

// Initializes a ModLib handle.
func NewModLib(gamepath string) (*ModLib, error) {
	cPath := C.CString(gamepath)
	defer C.free(unsafe.Pointer(cPath))

	var errorCode C.int = 0
	handle := C.modlib_init(cPath, &errorCode)

	if errorCode != 0 {
		return nil, errorFromCode(errorCode)
	}

	if handle == nil {
		return nil, errors.New("Unknown Error")
	}

	instance := &ModLib{ptr: handle}

	runtime.SetFinalizer(instance, (*ModLib).Close)

	return instance, nil
}

// Destroys a ModLib handle
func (m *ModLib) Close() {
	if m == nil {
		return
	}
	if m.ptr != nil {
		C.modlib_deinit(m.ptr)
		m.ptr = nil
	}
}

// Queues the mod to the internal mod pool.
func (m *ModLib) QueueMod(mod *Mod) error {
	if m.ptr == nil || mod == nil || mod.ptr == nil {
		return errors.New("cannot queue nil mod")
	}

	errorCode := C.modlib_queueMod(m.ptr, mod.ptr)
	if errorCode != 0 {
		return errorFromCode(errorCode)
	}
	return nil
}

// Installs all currently queued mods.
func (m *ModLib) InstallMods() error {
	if m.ptr == nil {
		return errors.New("nil handle cannot install mods")
	}

	errorCode := C.modlib_installMods(m.ptr)
	if errorCode != 0 {
		return errorFromCode(errorCode)
	}
	return nil
}

// Loads a mod file into a mod handle.
func NewMod(file string) (*Mod, error) {
	cFile := C.CString(file)
	defer C.free(unsafe.Pointer(cFile))

	var errorCode C.int = 0
	handle := C.modlib_mod_load(cFile, &errorCode)

	if errorCode != 0 {
		return nil, errorFromCode(errorCode)
	}

	if handle == nil {
		return nil, errors.New("Unknown Error")
	}

	instance := &Mod{ptr: handle}

	runtime.SetFinalizer(instance, (*Mod).Close)

	return instance, nil
}

// Destroys a Mod handle
func (m *Mod) Close() {
	if m == nil {
		return
	}
	if m.ptr != nil {
		C.modlib_mod_deinit(m.ptr)
		m.ptr = nil
	}
}

// Gets properties from a mod handle
func (m *Mod) GetProperties() (*ModProperties, error) {
	var errorCode C.int = 0
	handle := C.modlib_mod_getproperties(m.ptr, &errorCode);
	if errorCode != 0 {
		return nil, errorFromCode(errorCode)
	}

	if handle == nil {
		return nil, errors.New("Unknown Error")
	}

	instance := &ModProperties{ptr: handle}

	runtime.SetFinalizer(instance, (*ModProperties).Close)

	return instance, nil
}

// Destroys a ModProperties handle
func (p *ModProperties) Close() {
	if p == nil || p.ptr == nil {
		return
	}
	C.modlib_modproperties_deinit(p.ptr)
	p.ptr = nil
}

// Gets author property from a ModProperty
func (p *ModProperties) Author() string {
	if p.ptr == nil || p.ptr.author == nil {
		return ""
	}
	return C.GoString(p.ptr.author)
}

// Gets name property from a ModProperty
func (p *ModProperties) Name() string {
	if p.ptr == nil || p.ptr.name == nil {
		return ""
	}
	return C.GoString(p.ptr.name)
}

// Gets author id from a ModProperty
func (p *ModProperties) ID() string {
	if p.ptr == nil || p.ptr.id == nil {
		return ""
	}
	return C.GoString(p.ptr.id)
}

// Gets version property from a ModProperty
func (p *ModProperties) Version() string {
	if p.ptr == nil || p.ptr.version == nil {
		return ""
	}
	return C.GoString(p.ptr.version)
}

// Gets source property from a ModProperty
func (p *ModProperties) Source() string {
	if p.ptr == nil || p.ptr.source == nil {
		return ""
	}
	return C.GoString(p.ptr.source)
}

// Gets path from a ModProperty
func (p *ModProperties) Path() string {
	if p.ptr == nil || p.ptr.path == nil {
		return ""
	}
	return C.GoString(p.ptr.path)
}

// Gets format from a ModProperty
func (p *ModProperties) Format() ModFormat {
	if p.ptr == nil || p.ptr.path == nil {
		return Hazemod
	}
	return ModFormat(p.ptr.format)
}

// Gets dependencies as a slice of id's from a ModProperty
func (p *ModProperties) Dependencies() []string {
	if p.ptr == nil || p.ptr.dependencies == nil || p.ptr.dependency_count == 0 {
		return nil
	}

	count := int(p.ptr.dependency_count)
	cSlice := (*[1 << 30]*C.char)(unsafe.Pointer(*p.ptr.dependencies))[:count:count]

	goStrings := make([]string, count)
	for i, cStr := range cSlice {
		if cStr != nil {
			goStrings[i] = C.GoString(cStr)
		}
	}
	return goStrings
}

// Gets soft dependencies as a slice of id's from a ModProperty
func (p *ModProperties) SoftDependencies() []string {
	if p.ptr == nil || p.ptr.soft_dependencies == nil || p.ptr.soft_dependency_count == 0 {
		return nil
	}

	count := int(p.ptr.soft_dependency_count)
	cSlice := (*[1 << 30]*C.char)(unsafe.Pointer(*p.ptr.soft_dependencies))[:count:count]

	goStrings := make([]string, count)
	for i, cStr := range cSlice {
		if cStr != nil {
			goStrings[i] = C.GoString(cStr)
		}
	}
	return goStrings
}

//helper function
func errorFromCode(code C.int) error {
	cMsg := C.modlib_getErrorMessageFromCode(code)
	if cMsg == nil {
		return errors.New("unknown error code")
	}
	return errors.New(C.GoString(cMsg))
}