const std = @import("std");
const lib = @import("modlib");

const Error = lib.Error;

/// Handle for mod injection
pub const modlib = opaque {};

/// Handle for a mod instance
pub const mod = opaque {};

pub const mod_format = enum(c_int) {
    hazemod = 0,
    zip = 1,
};

/// Mod properties struct
pub const mod_properties = extern struct {
    author: [*c]const u8 = null,
    name: [*c]const u8 = null,
    id: [*c]const u8 = null,
    version: [*c]const u8 = null,
    source: [*c]const u8 = null,
    path: [*c]const u8 = null,
    format: mod_format = .hazemod,
    soft_dependencies: ?[*][*c]const u8 = null,
    soft_dependency_count: c_ulonglong = 0,
    dependencies: ?[*][*c]const u8 = null,
    dependency_count: c_ulonglong = 0,
};

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
        if (err) |errptr| errptr.* = @intFromError(Error.FileNotFound);
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
        if (err) |errptr| errptr.* = @intFromError(Error.FileNotFound);
        return null;
    }
}

/// gets and returns the properties from a mod handle
export fn modlib_mod_getproperties(handle: *mod, err: ?*c_int) callconv(.c) ?*mod_properties {
    const ptr: *lib.Mod = @ptrCast(@alignCast(handle));

    return getPropertiesSafe(ptr.*) catch |e| {
        if (err) |errptr| errptr.* = @intFromError(e);
        return null;
    };
}

/// destroys and frees all memory taken by the given property handle.
export fn modlib_modproperties_deinit(handle: *mod_properties) callconv(.c) void {
    if(handle.author) |ptr| std.heap.c_allocator.free(std.mem.span(ptr));
    if(handle.name) |ptr| std.heap.c_allocator.free(std.mem.span(ptr));
    if(handle.id) |ptr| std.heap.c_allocator.free(std.mem.span(ptr));
    if(handle.version) |ptr| std.heap.c_allocator.free(std.mem.span(ptr));
    if(handle.source) |ptr|std.heap.c_allocator.free(std.mem.span(ptr));

    if (handle.soft_dependencies) |deps| {
        const slice = deps[0..handle.soft_dependency_count];
        for (slice) |dep| {
            if (dep) |dptr| std.heap.c_allocator.free(std.mem.span(dptr));
        }
        std.heap.c_allocator.free(slice);
    }

    if (handle.dependencies) |deps| {
        const slice = deps[0..handle.dependency_count];
        for (slice) |dep| {
            if (dep) |dptr| std.heap.c_allocator.free(std.mem.span(dptr));
        }
        std.heap.c_allocator.free(slice);
    }

    std.heap.c_allocator.destroy(handle);
}

/// Destroys a ModLib handle
export fn modlib_mod_deinit(handle: *mod) callconv(.c) void {
    const ptr: *lib.Mod = @ptrCast(@alignCast(handle));
    ptr.deinit();
    std.heap.c_allocator.destroy(ptr);
}

/// Returns error string
export fn modlib_getErrorMessageFromCode(code: c_int) [*c]const u8 {
    return switch (@errorFromInt(@as(u16, @intCast(code)))) {
        Error.Success => "No error",
        Error.FileNotFound => "File Not Found Exception",
        Error.FileOpenFailure => "File Open Exception",
        Error.FileReadError => "File Read Exception",
        Error.FileWriteError => "File Write Exception",
        Error.OutOfMemory => "Out of Memory Exception",
        Error.ThreadingError => "Threading Error",
        Error.SyntaxError => "Syntax Error",
        Error.MissingDependency => "Missing Dependency",
        Error.ClassNotFound => "Class Not Found Exception",
        Error.FunctionNotFound => "Function Not Found Exception",
        Error.PropertyNotFound => "Property Not Found Exception",
        Error.EnumNotFound => "Enum Not Found Exception",
        Error.PropertiesOpenError => "Properties Open Exception",
        Error.PropertiesReadError => "Properties Read Exception",
        Error.PropertiesParseError => "Properties Parse Exception",
        else => "Unknown Error Occured",
    };
}

//helper
fn getPropertiesSafe(base_mod: lib.Mod) !*mod_properties {
    const allocator = std.heap.c_allocator;
    
    const base_prop = base_mod.properties;

    const author = try allocator.dupeSentinel(u8, base_prop.author, 0);
    errdefer allocator.free(author);

    const name = try allocator.dupeSentinel(u8, base_prop.name, 0);
    errdefer allocator.free(name);

    const id = try allocator.dupeSentinel(u8, base_prop.id, 0);
    errdefer allocator.free(id);

    const version = try allocator.dupeSentinel(u8, base_prop.version, 0);
    errdefer allocator.free(version);

    const source = try allocator.dupeSentinel(u8, base_prop.source, 0);
    errdefer allocator.free(source);

    const path = try allocator.dupeSentinel(u8, base_mod.path, 0);
    errdefer allocator.free(path);

    const format = switch (base_mod.format) {
        lib.ModFormat.HAZEMOD => mod_format.hazemod,
        lib.ModFormat.ZIP => mod_format.zip,
    };

    var dep_ptrs: ?[*][*c]const u8 = null;
    var dep_count: usize = 0;
    if (base_prop.dependencies) |deps| {
        dep_count = deps.len;
        var arr = try allocator.alloc([*c]const u8, dep_count);
        errdefer allocator.free(arr);

        var success_count: usize = 0;
        errdefer {
            for (0..success_count) |i| allocator.free(std.mem.span(arr[i]));
        }

        for (deps, 0..) |dep, i| {
            arr[i] = try allocator.dupeSentinel(u8, dep, 0);
            success_count += 1;
        }
        dep_ptrs = arr.ptr;
    }

    var soft_dep_ptrs: ?[*][*c]const u8 = null;
    var soft_dep_count: usize = 0;
    if (base_prop.soft_dependencies) |deps| {
        soft_dep_count = deps.len;
        var arr = try allocator.alloc([*c]const u8, soft_dep_count);
        errdefer allocator.free(arr);

        var success_count: usize = 0;
        errdefer {
            for (0..success_count) |i| allocator.free(std.mem.span(arr[i]));
        }

        for (deps, 0..) |dep, i| {
            arr[i] = try allocator.dupeSentinel(u8, dep, 0);
            success_count += 1;
        }
        soft_dep_ptrs = arr.ptr;
    }

    const out = try allocator.create(mod_properties);
    errdefer allocator.destroy(out); // Clean up container if anything below fails (though nothing else does here)

    out.* = .{
        .author = author,
        .name = name,
        .id = id,
        .version = version,
        .source = source,
        .path = path,
        .format = format,
        .soft_dependencies = soft_dep_ptrs,
        .soft_dependency_count = soft_dep_count,
        .dependencies = dep_ptrs,
        .dependency_count = dep_count,
    };

    return out;
}