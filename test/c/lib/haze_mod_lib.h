#ifndef haze_mod_lib_def
#define haze_mod_lib_def

#ifdef __cplusplus
extern "C" {
#endif

#if defined(SWIG) || defined(_WIN32)
  #define DLLIMPORT
#else
  #define DLLIMPORT __attribute__ ((visibility ("default")))
#endif

#if !defined(SWIG)
#define MODLIB_FILENOTFOUND 2
#define MODLIB_FILEOPENFAILURE 3
#define MODLIB_FILEREADERROR 4
#define MODLIB_FILEWRITEERROR 5
#define MODLIB_OUTOFMEMORY 6
#define MODLIB_THREADINGERROR 7
#define MODLIB_SYNTAXERROR 8
#define MODLIB_MISSINGDEPENDENCY 9
#define MODLIB_CLASSNOTFOUND 10
#define MODLIB_FUNCTIONNOTFOUND 11
#define MODLIB_PROPERTYNOTFOUND 12
#define MODLIB_ENUMNOTFOUND 13
#define MODLIB_PROPERTIESOPENERROR 14
#define MODLIB_PROPERTIESREADERROR 15
#define MODLIB_PROPERTIESPARSEERROR 16
#define MODLIB_UNKNOWNERROR 17
#endif

/*
Handle for mod injection
*/
typedef struct modlib_t modlib;
/*
Handle for a mod instance
*/
typedef struct mod_t mod;
/*
enum for mod format
*/
typedef enum modformat_t {
  hazemod = 0,
  zip = 1,
} modformat;
/*
handle for mod properties
*/
typedef struct modproperties_t {
  char* author;
  char* name;
  char* id;
  char* version;
  char* source;
  char* path;
  modformat format;
  char** soft_dependencies;
  unsigned long long soft_dependency_count;
  char** dependencies;
  unsigned long long dependency_count;
} modproperties;
/*
Initializes a ModLib handle.

\param game_path path to the game directory.
\param err optional pointer to error field

\returns The initialized modlib handle. (null on error).

\note Do not forget to call deinit on the returned handle when finished.
*/
DLLIMPORT modlib* modlib_init(const char* game_path, int* err);
/*
Destroys a modlib handle
*/
DLLIMPORT void modlib_deinit(modlib* handle);
/*
Queues the mod to the internal mod pool.
Call installMods to install all the mods at once.

\param handle modlib handle to install under.
\param mod_handle mod handle to add to the pool.

\returns 0 on success, error code on failure.
*/
DLLIMPORT int modlib_queueMod(modlib* handle, mod* mod_handle);
/*
Installs all currently queued mods.

\param handle modlib handle to install under.

\returns 0 on success, error code on failure.

\note All zip mods will be installed first, in order of queue index.
\note Dependecies for hazemod mods will be evaluated and respected.
\note mod pool will be purged on installation success.
*/
DLLIMPORT int modlib_installMods(modlib* handle);
/*
Load a mod file into a mod handle.

\param file path to the mod file.
\param err optional pointer to error field

\returns The initialized mod handle. (null on error).

\note Do not forget to call deinit on the returned handle when finished.
*/
DLLIMPORT mod* modlib_mod_load(const char* file, int* err);
/*
Destroys a mod handle
*/
DLLIMPORT void modlib_mod_deinit(mod* handle);
/*
Gets properties from a mod handle

\param handle mod handle to get properties from
\param err optional pointer to error field

\returns
properties handle containing properties of input mod.
*/
DLLIMPORT modproperties* modlib_mod_getproperties(mod* handle, int* err);
/*
Frees resources from a properties handle
*/
DLLIMPORT void modlib_modproperties_deinit(modproperties* handle);
/*
Returns error string
*/
DLLIMPORT char* modlib_getErrorMessageFromCode(int code);

#ifdef __cplusplus
}
#endif
#endif