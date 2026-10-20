const std = @import("std");

pub const ThreadMap = struct {
    mutex: std.Io.Mutex = .init,
    map: std.StringHashMapUnmanaged(*std.Io.Mutex) = .empty,

    pub fn deinit(self: *ThreadMap, io: std.Io, allocator: std.mem.Allocator) void {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        var it = self.map.iterator();
        while(it.next()) |entry| {
            allocator.destroy(entry.value_ptr.*);
            allocator.free(entry.key_ptr.*);
        }
        self.map.deinit(allocator);
    }

    pub fn getOrCreate(self: *ThreadMap, io: std.Io, allocator: std.mem.Allocator, path: []const u8) std.mem.Allocator.Error!*std.Io.Mutex {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        if(self.map.get(path)) |m| return m;

        const m = try allocator.create(std.Io.Mutex);
        errdefer allocator.destroy(m);
        m.* = .init;

        const key = try allocator.dupe(u8, path);
        errdefer allocator.free(key);

        try self.map.put(allocator, key, m);

        return m;
    }
};