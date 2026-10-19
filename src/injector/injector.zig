const std = @import("std");
const common = @import("../common.zig");
const scriptedit = @import("../parser/scriptedit.zig");

const InjectorError = common.InjectorError;
const ScriptEdit = scriptedit.ScriptEdit;

pub fn executeEdit(step: *ScriptEdit, allocator: std.mem.Allocator, io: std.Io) InjectorError!void {
    defer {
        step.deinit(allocator);
        allocator.destroy(step);
    }
    _ = io;
}
