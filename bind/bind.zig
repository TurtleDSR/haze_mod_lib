const std = @import("std");
const lib = @import("modlib");

const Error = lib.Error;

/// Handle for mod injection
pub const modlib = opaque {};

/// Handle for a mod instance
pub const mod = opaque {};

/// Initializes a ModLib handle.
///
/// **Parameters:**
///
/// *game_path* - path to the game directory.
///
/// *err* - optional pointer to error field
///
/// **Returns:**
///
/// The initialized modlib handle. (null on error).
///
/// **Note**
///
/// Do not forget to call deinit on the returned handle when finished.
export fn modlib_init(game_path: [*c]const u8, err: ?*c_int) callconv(.c) ?*modlib {
    const allocator = std.heap.c_allocator;
    if (game_path) |path_in| {
        const path: [:0]const u8 = std.mem.span(path_in);

        const handle_ptr = allocator.create(lib.ModLib) catch {
            if (err) |errptr| errptr.* = @intFromError(Error.OutOfMemory);
            return null;
        };

        handle_ptr.* = lib.ModLib.init(path, allocator) catch |e| {
            allocator.destroy(handle_ptr);
            if (err) |errptr| errptr.* = @intFromError(e);
            return null;
        };

        return @ptrCast(@alignCast(handle_ptr));
    } else {
        return null;
    }
}

/// Destroys a ModLib handle
export fn modlib_deinit(handle: *modlib) callconv(.c) void {
    const ptr: *lib.ModLib = @ptrCast(@alignCast(handle));
    ptr.deinit();
    std.heap.c_allocator.destroy(ptr);
}

/// Queues the mod to the internal mod pool.
/// Call installMods to install all the mods at once.
///
/// **Parameters:**
///
/// *handle* - modlib handle to install under.
///
/// *mod_handle* - mod handle to add to the pool.
///
/// **Returns:**
///
/// 0 on success, error code on failure.
export fn modlib_queueMod(handle: *modlib, mod_handle: *mod) callconv(.c) c_int {
    const libptr: *lib.ModLib = @ptrCast(@alignCast(handle));
    const modptr: *lib.Mod = @ptrCast(@alignCast(mod_handle));

    libptr.queueMod(modptr.*) catch |err| {
        return @intFromError(err);
    };
    return 0;
}

/// Installs all currently queued mods.
///
/// **Parameters:**
///
/// *handle* - modlib handle to install under.
///
/// **Note:**
///
/// All zip mods will be installed first, in order of queue index.
/// Dependecies for hazemod mods will be evaluated and respected.
///
/// mod pool will be purged on installation success.
///
/// **Returns:**
///
/// 0 on success, error code on failure.
export fn modlib_installMods(handle: *modlib) callconv(.c) c_int {
    var io = std.Io.Threaded.init(std.heap.c_allocator, .{});
    const ptr: *lib.ModLib = @ptrCast(@alignCast(handle));
    ptr.installMods(io.io()) catch |err| {
        return @intFromError(err);
    };
    return 0;
}

/// Load a mod file into a mod handle.
///
/// **Parameters:**
///
/// *file* - path to the mod file.
///
/// *err* - optional pointer to error field
///
/// **Returns**
///
/// The initialized mod handle. (null on error).
///
/// **Note**
///
/// Do not forget to call deinit on the returned handle when finished.
export fn modlib_mod_load(file: [*c]const u8, err: ?*c_int) callconv(.c) ?*mod {
    const allocator = std.heap.c_allocator;
    if (file) |path_in| {
        const path: [:0]const u8 = std.mem.span(path_in);

        const handle_ptr = allocator.create(lib.Mod) catch {
            if (err) |errptr| errptr.* = @intFromError(Error.OutOfMemory);
            return null;
        };

        handle_ptr.* = lib.Mod.load(path, allocator) catch |e| {
            allocator.destroy(handle_ptr);
            if (err) |errptr| errptr.* = @intFromError(e);
            return null;
        };

        return @ptrCast(@alignCast(handle_ptr));
    } else {
        return null;
    }
}

/// Destroys a ModLib handle
export fn modlib_mod_deinit(handle: *mod) callconv(.c) void {
    const ptr: *lib.Mod = @ptrCast(@alignCast(handle));
    ptr.deinit();
    std.heap.c_allocator.destroy(ptr);
}
