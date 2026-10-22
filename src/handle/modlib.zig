const std = @import("std");
const common = @import("../common.zig");

const modpool = @import("../pool/modpool.zig");
const scriptedit = @import("../parser/scriptedit.zig");
const threadmap = @import("../injector/threadmap.zig");

const parser = @import("../parser/parser.zig");
const injector = @import("../injector/injector.zig");

const zip = common.zip;

const Error = common.Error;
const ModFormat = common.ModFormat;
const Mod = common.Mod;

const ModPool = modpool.ModPool;

const ScriptEdit = scriptedit.ScriptEdit;

const ThreadMap = threadmap.ThreadMap;

/// Handle for mod injection
pub const ModLib = struct {
    /// Path to the games script folder on disk. (<Steam_Common>/ItTakesTwo/Nuts/ for example)
    scripts_path: [:0]const u8,
    /// Path to the games script folder on disk. (<Steam_Common>/ItTakesTwo/Nuts/Content/Paks/ for example)
    pak_path: [:0]const u8,
    /// **Note:**
    ///
    /// This field is intended to be used only internally.
    _hazemod_mod_pool: ModPool = .empty,
    /// **Note:**
    ///
    /// This field is intended to be used only internally.
    _hazemod_mod_queue: std.PriorityQueue(Mod, void, orderMods) = .empty,
    /// **Note:**
    ///
    /// This field is intended to be used only internally.
    _hazemod_levels: std.array_hash_map.String(u8) = .empty,
    /// **Note:**
    ///
    /// This field is intended to be used only internally.
    _zip_mod_pool: std.ArrayList(Mod) = .empty,
    /// **Note:**
    ///
    /// This field is intended to be used only internally.
    _allocator: std.mem.Allocator,

    /// Initializes a ModLib handle.
    ///
    /// **Parameters:**
    ///
    /// *game_path* - path to the game directory.
    ///
    /// *allocator* - allocator.
    ///
    /// **Returns:**
    ///
    /// Resulting ModLib handle.
    ///
    /// **Note**
    ///
    /// Do not forget to call deinit on the returned handle when finished.
    pub fn init(game_path: [:0]const u8, allocator: std.mem.Allocator) Error!ModLib {
        const handle: ModLib = .{
            .scripts_path = std.fmt.allocPrintSentinel(allocator, "{s}/Script/", .{game_path}, 0) catch return Error.OutOfMemory,
            .pak_path = std.fmt.allocPrintSentinel(allocator, "{s}/Content/Paks/", .{game_path}, 0) catch return Error.OutOfMemory,
            ._allocator = allocator,
        };

        return handle;
    }

    /// Destroys a ModLib handle
    pub fn deinit(self: *ModLib) void {
        self._allocator.free(self.scripts_path);
        self._allocator.free(self.pak_path);

        self._hazemod_mod_pool.destroy(self._allocator);
        self._hazemod_mod_queue.deinit(self._allocator);
        self._zip_mod_pool.deinit(self._allocator);
        self._hazemod_levels.deinit(self._allocator);
    }

    /// Queues the mod to the internal mod pool.
    /// Call installMods to install all the mods at once.
    ///
    /// **Parameters:**
    ///
    /// *mod* - mod handle to add to the pool.
    ///
    /// **Note:**
    ///
    /// May allocate memory.
    pub fn queueMod(self: *ModLib, mod: Mod) Error!void {
        switch (mod.format) {
            ModFormat.ZIP => {
                self._zip_mod_pool.append(self._allocator, mod) catch return Error.OutOfMemory;
            },
            ModFormat.HAZEMOD => {
                self._hazemod_mod_pool.addMod(self._allocator, mod) catch return Error.OutOfMemory;
            },
        }
    }

    /// Installs all currently queued mods.
    ///
    /// **Note:**
    ///
    /// All zip mods will be installed first, in order of queue index.
    /// Dependecies for hazemod mods will be evaluated and respected.
    ///
    /// mod pool will be purged on installation success.
    pub fn installMods(self: *ModLib, io: std.Io) Error!void {
        //install zip mods.
        //must be done sequentially since theres no dependency system.
        for (self._zip_mod_pool.items) |mod| {
            try self.installZipMod(mod);
        }

        if (self._hazemod_mod_pool.keys.items.len > 0) { //skip installing hazemods if they arent present
            self._hazemod_levels.clearRetainingCapacity();
            //order hazemod handles into queue.
            while (self._hazemod_mod_pool.keys.items.len > 0) {
                const key = self._hazemod_mod_pool.pop(0) catch return Error.MissingDependency;
                _ = try self.orderModR(key);
            }

            var buf: [256]*ScriptEdit = @splat(@constCast(&ScriptEdit{})); //256 should avoid wait time most of the time i think

            var level: u8 = 0;

            //use cores / 2 as our thread count
            //unless mod count is less than that, we use modcount
            const thread_count = @min(self._hazemod_mod_queue.items.len, @max((std.Thread.getCpuCount() catch return Error.ThreadingError) / 2, 1));
            var thread_list: std.ArrayList(std.Thread) = .empty;
            thread_list.ensureTotalCapacity(self._allocator, thread_count) catch return Error.OutOfMemory;
            defer thread_list.deinit(self._allocator);

            var edit_queue: std.Io.Queue(*ScriptEdit) = .init(&buf);
            var edit_count: std.atomic.Value(u8) = .init(0);

            var thread_map: ThreadMap = .{}; //used to stop race conditions of files
            defer thread_map.deinit(io, self._allocator);
            var thread_error: std.atomic.Value(u16) = .init(@intFromError(Error.Success));

            var task_list: std.ArrayList(std.Io.Future(Error!void)) = .empty;
            defer blk: {
                edit_queue.close(io);

                for (thread_list.items) |thread| {
                    thread.join();
                }
                task_list.deinit(self._allocator);

                break :blk;
            }

            for (0..thread_count) |_| {
                const thread = std.Thread.spawn(.{ .allocator = self._allocator }, threadExecuteEdits, .{ self.scripts_path, &thread_map, &edit_queue, &edit_count, &thread_error, io, self._allocator }) catch return Error.ThreadingError;
                thread_list.appendAssumeCapacity(thread);
            }

            while (self._hazemod_mod_queue.items.len > 0) : (level += 1) {
                while (self._hazemod_mod_queue.items.len > 0 and self._hazemod_mod_queue.peek().?.dependency_level == level) { //start all mods of the current level
                    if (self._hazemod_mod_queue.pop()) |m| {
                        const task: std.Io.Future(Error!void) = io.async(workerStreamEdits, .{ self, m, &edit_queue, &edit_count, self._allocator, io });
                        task_list.append(self._allocator, task) catch return Error.OutOfMemory;
                    } else {
                        return Error.UnknownError;
                    }
                }

                var task_error: Error = Error.Success;

                for (task_list.items) |*t| { //await all tasks finished
                    t.await(io) catch |err| {
                        task_error = err;
                    };
                }

                task_list.clearRetainingCapacity();

                while (edit_count.load(.acquire) > 0) { //wait until all edits are complete
                    std.Thread.yield() catch {};
                }

                if (task_error != Error.Success) return task_error;
                const err = thread_error.load(.acquire);
                if (@errorFromInt(err) != Error.Success) return @errorCast(@errorFromInt(err));
            }
        }

        self._hazemod_mod_pool.purge();
        self._zip_mod_pool.clearRetainingCapacity();
        self._hazemod_mod_queue.clearRetainingCapacity();
    }

    /// Installs a mod using the legacy zip format.
    ///
    /// **Params:**
    ///
    /// *mod* - mod handle to inject.
    fn installZipMod(self: *ModLib, mod: Mod) Error!void {
        zip.extract(mod.path, self.scripts_path, null, null) catch |err| {
            switch (err) {
                zip.ZipError.FileNotFound => return Error.FileNotFound,
                zip.ZipError.FileOpenFailure => return Error.FileOpenFailure,
                zip.ZipError.FReadError => return Error.FileReadError,
                zip.ZipError.FWriteError => return Error.FileWriteError,
                else => return Error.UnknownError,
            }
        };
    }

    fn orderModR(self: *ModLib, key: []const u8) Error!u8 {
        const mod_index = self._hazemod_mod_pool.findMod(key) catch return Error.MissingDependency;

        if (self._hazemod_mod_pool.nodes.items[mod_index].mod) |m| {
            var level: u8 = 0;

            //handle dependencies
            if (m.properties.dependencies) |deps| {
                for (deps) |dep| {
                    if (self._hazemod_levels.get(dep)) |lev| {
                        level = @max(level, lev + 1);
                        continue;
                    }

                    const lev = try self.orderModR(dep);
                    level = @max(level, lev + 1);
                }
            }

            //handle soft dependencies
            if (m.properties.soft_dependencies) |deps| {
                for (deps) |dep| {
                    if (self._hazemod_levels.get(dep)) |lev| {
                        level = @max(level, lev + 1);
                        continue;
                    }

                    const lev = self.orderModR(dep) catch {
                        continue;
                    }; //ignore error since dependency isnt required
                    level = @max(level, lev + 1);
                }
            }

            if (self._hazemod_mod_pool.nodes.items[mod_index].mod != null) {
                self._hazemod_mod_pool.nodes.items[mod_index].mod.?.dependency_level = level;
            }

            self._hazemod_mod_queue.push(self._allocator, m) catch return Error.OutOfMemory;

            self._hazemod_mod_pool.removeKey(key);
            self._hazemod_levels.put(self._allocator, key, level) catch return Error.OutOfMemory;

            return level;
        } else {
            return Error.MissingDependency;
        }
    }

    /// Streams edits to the queue to be executed multithreaded
    fn workerStreamEdits(self: *ModLib, mod: Mod, queue: *std.Io.Queue(*ScriptEdit), queue_size: *std.atomic.Value(u8), allocator: std.mem.Allocator, io: std.Io) Error!void {
        var z = zip.open(mod.path, zip.defaultCompressionLevel, 'r') catch return Error.FileOpenFailure;
        {
            defer z.close();

            const entries = z.getEntryTotal() catch return Error.FileReadError;

            for (0..entries) |i| {
                z.openEntryByIndex(i) catch return Error.FileReadError;
                {
                    defer z.closeEntry();

                    const entry_name = z.getEntryName() catch return Error.FileReadError;

                    if (std.mem.eql(u8, std.Io.Dir.path.extension(entry_name), ".as")) { //check if file is .as
                        const contents = z.readEntry(allocator) catch return Error.FileReadError;
                        defer allocator.free(contents);
                        try parser.streamEdits(entry_name, contents, queue, queue_size, allocator, io);
                    }

                    if (std.mem.eql(u8, std.Io.Dir.path.extension(entry_name), ".pak")) { //check if file is .pak
                        const basename = @constCast(std.Io.Dir.path.basename(entry_name));
                        const dot_index = std.mem.findLast(u8, basename, ".");
                        var pak_name: []u8 = undefined;

                        if (dot_index) |d| {
                            pak_name = basename[0..d];
                        } else {
                            return Error.UnknownError;
                        }

                        var pak_name_new: ?[]u8 = null;
                        defer if (pak_name_new) |p| allocator.free(p);

                        if (!std.mem.endsWith(u8, pak_name, "_P")) {
                            pak_name_new = std.fmt.allocPrint(allocator, "{s}{s}", .{ pak_name, "_P" }) catch return Error.OutOfMemory;

                            pak_name = pak_name_new orelse pak_name;
                        }

                        const path: [:0]u8 = std.fmt.allocPrintSentinel(allocator, "{s}/{s}{s}", .{ self.pak_path, pak_name, ".pak" }, 0) catch return Error.OutOfMemory;
                        defer allocator.free(path);

                        z.fileReadEntry(path) catch return Error.FileWriteError;
                    }
                }
            }
        }
    }
};

/// Executes edits from the queue multithreaded
fn threadExecuteEdits(dir: []const u8, filemap: *ThreadMap, queue: *std.Io.Queue(*ScriptEdit), queue_size: *std.atomic.Value(u8), error_field: *std.atomic.Value(u16), io: std.Io, allocator: std.mem.Allocator) Error!void {
    while (queue.getOne(io)) |edit| {
        defer _ = queue_size.fetchSub(1, .release);
        injector.executeEdit(dir, edit, filemap, allocator, io) catch |err| {
            std.debug.print("ERROR: {}\n", .{err});
            error_field.store(@intFromError(err), .release);
        };
    } else |_| {
        return;
    }
}

/// Used for ordering mods in the installation queue.
fn orderMods(context: void, a: Mod, b: Mod) std.math.Order {
    _ = context; //ignored

    if (a.dependency_level < b.dependency_level) {
        return std.math.Order.lt;
    } else if (a.dependency_level == b.dependency_level) {
        return std.math.Order.eq;
    } else {
        return std.math.Order.gt;
    }
}
