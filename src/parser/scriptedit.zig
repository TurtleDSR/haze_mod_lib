const std = @import("std");

pub const ScriptEdit = struct {
    operation: Operation = .NONE,
    file: []const u8 = "",
    data: []const u8 = "",
    target: Target = .{},
    
    pub fn deinit(self: *ScriptEdit, allocator: std.mem.Allocator) void {
        if(self.data.len != 0) {
            allocator.free(self.data);
        }

        self.target.deinit(allocator);
    }

    pub fn print(self: ScriptEdit) void {
        std.debug.print("Edit: .{{\n    operation: {}\n    file: {s}\n    data: {{\n{b64}\n    }}\n    target: {} - {s}\n}}\n", .{self.operation, self.file, self.data, self.target.scope, self.target.identifier});
    }
};

pub const Target = struct {
    scope: Scope = .NONE,
    identifier: []const u8 = "",
    target: ?*Target = null,

    pub fn deinit(self: Target, allocator: std.mem.Allocator) void {
        if(self.target) |t| {
            t.deinit(allocator);
            allocator.destroy(t);
        }
    }
};

pub const Operation = enum {
    REPLACE,
    ADD,
    NONE,
};

pub const Scope = enum {
    FILE,
    AUTO,
    GLOBAL,
    IMPORT,
    CLASS,
    FUNCTION,
    PROPERTY,
    ENUM,
    NONE, //default
};