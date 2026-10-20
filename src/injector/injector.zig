const std = @import("std");
const common = @import("../common.zig");
const scriptedit = @import("../parser/scriptedit.zig");
const threadmap = @import("threadmap.zig");

const Error = common.Error;
const ScriptEdit = scriptedit.ScriptEdit;
const ThreadMap = threadmap.ThreadMap;

const Scope = scriptedit.Scope;
const Operation = scriptedit.Operation;

pub fn executeEdit(dir: []const u8, step: *ScriptEdit, map: *ThreadMap, allocator: std.mem.Allocator, io: std.Io) Error!void {
    defer {
        step.deinit(allocator);
        allocator.destroy(step);
    }

    var mutex = map.getOrCreate(io, allocator, step.file) catch return Error.OutOfMemory;
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);

    const path = std.fmt.allocPrint(allocator, "{s}{s}", .{ dir, step.file }) catch return Error.OutOfMemory;
    defer allocator.free(path);

    const parent_dir = std.Io.Dir.path.dirname(path) orelse ".";
    std.Io.Dir.cwd().createDirPath(io, parent_dir) catch return Error.FileOpenFailure;

    var file = std.Io.Dir.cwd().createFile(io, path, .{
        .lock = .exclusive,
        .read = true,
        .truncate = false,
    }) catch return Error.FileOpenFailure;
    defer file.close(io);

    const file_length = file.length(io) catch return Error.FileReadError;
    const file_contents = allocator.alloc(u8, file_length) catch return Error.OutOfMemory;
    defer allocator.free(file_contents);

    var reader = file.reader(io, file_contents);
    reader.interface.readSliceAll(file_contents) catch return Error.FileReadError;

    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(allocator);
    buf.appendSlice(allocator, file_contents) catch return Error.OutOfMemory;

    try resolveEdit(step, &buf, allocator);

    var writer = file.writer(io, file_contents);
    writer.interface.writeAll(buf.items) catch return Error.FileWriteError;
    writer.end() catch return Error.FileWriteError;
}

/// Kinda grimy function that switches over all valid scope cases.
/// If it aint broke dont fix it, also jump tables are fast ig.
fn resolveEdit(edit: *ScriptEdit, buffer: *std.ArrayList(u8), allocator: std.mem.Allocator) Error!void {
    switch (edit.target.scope) {
        Scope.IMPORT => switch (edit.operation) { //import operation only
            Operation.ADD => { //add import statement
                buffer.insertSlice(allocator, 0, edit.data) catch return Error.FileWriteError;
            },
            else => return Error.SyntaxError,
        },

        Scope.GLOBAL => switch (edit.operation) { //global scope
            Operation.ADD => { //append code to end of file
                buffer.appendSlice(allocator, edit.data) catch return Error.OutOfMemory;
            },

            Operation.REPLACE => if (edit.target.target) |t| switch (t.scope) {
                Scope.FUNCTION => { //find first instance of function by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getFunctionWindow(window, buffer, edit.target.target.?.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                Scope.ENUM => { //find first instance of enum by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getEnumWindow(window, buffer, edit.target.target.?.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                Scope.PROPERTY => { //find first instance of property by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getPropertyWindow(window, buffer, edit.target.target.?.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                Scope.CLASS => { //find class by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getClassWindow(window, buffer, edit.target.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                else => return Error.SyntaxError,
            } else { //replace entire file
                buffer.clearRetainingCapacity();
                buffer.appendSlice(allocator, edit.data) catch return Error.OutOfMemory;
            },

            else => return Error.SyntaxError,
        },

        Scope.AUTO => switch (edit.operation) {
            Operation.REPLACE => if (edit.target.target) |t| switch (t.scope) {
                Scope.FUNCTION => { //find first instance of function by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getFunctionWindow(window, buffer, edit.target.target.?.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                Scope.ENUM => { //find first instance of enum by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getEnumWindow(window, buffer, edit.target.target.?.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                Scope.PROPERTY => { //find first instance of property by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getPropertyWindow(window, buffer, edit.target.target.?.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                Scope.CLASS => { //find class by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getClassWindow(window, buffer, edit.target.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },
                else => return Error.SyntaxError,
            } else return Error.SyntaxError,

            Operation.ADD => {
                var window: Window = .{
                    .start = 0,
                    .end = buffer.items.len,
                };

                window = try getFirstClassWindow(window, buffer);
                buffer.insertSlice(allocator, window.end - 1, edit.data) catch return Error.FileWriteError;
            },

            else => return Error.SyntaxError,
        },

        Scope.CLASS => if (edit.target.target) |t| switch (edit.operation) {
            Operation.REPLACE => switch (t.scope) {
                Scope.FUNCTION => { //find function under class by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getClassWindow(window, buffer, edit.target.identifier, allocator);
                    window = try getFunctionWindow(window, buffer, edit.target.target.?.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                Scope.ENUM => { //find enum under class by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getClassWindow(window, buffer, edit.target.identifier, allocator);
                    window = try getEnumWindow(window, buffer, edit.target.target.?.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                Scope.PROPERTY => { //find property under class by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getClassWindow(window, buffer, edit.target.identifier, allocator);
                    window = try getPropertyWindow(window, buffer, edit.target.target.?.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },

                Scope.CLASS => { //find class by identifier and patch it
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getClassWindow(window, buffer, edit.target.identifier, allocator);
                    buffer.replaceRange(allocator, window.start, window.end - window.start, edit.data) catch return Error.FileWriteError;
                },
                else => return Error.SyntaxError,
            },

            Operation.ADD => switch (t.scope) {
                Scope.FUNCTION => { //add function under class
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getClassWindow(window, buffer, edit.target.identifier, allocator);
                    buffer.insertSlice(allocator, window.end - 1, edit.data) catch return Error.FileWriteError;
                },

                Scope.ENUM => { //add enum under class
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getClassWindow(window, buffer, edit.target.identifier, allocator);
                    buffer.insertSlice(allocator, window.end - 1, edit.data) catch return Error.FileWriteError;
                },

                Scope.PROPERTY => { //add property under class
                    var window: Window = .{
                        .start = 0,
                        .end = buffer.items.len,
                    };

                    window = try getClassWindow(window, buffer, edit.target.identifier, allocator);
                    buffer.insertSlice(allocator, window.end - 1, edit.data) catch return Error.FileWriteError;
                },
                else => return Error.SyntaxError,
            },
            else => return Error.SyntaxError,
        } else return Error.SyntaxError,
        else => return Error.SyntaxError,
    }
}

const Window = struct {
    start: usize = 0,
    end: usize = 0,
};

fn findString(window: Window, buffer: *std.ArrayList(u8), string: []const u8) ?usize {
    if (string.len == 0 or window.end - window.start < string.len) return null;

    var i = window.start;
    while (i <= window.end - string.len) : (i += 1) {
        if (std.mem.startsWith(u8, buffer.items[i..window.end], string)) {
            return i;
        }
    }
    return null;
}

fn findClosingBracket(window: Window, buffer: *std.ArrayList(u8)) ?usize {
    var count: usize = 0;
    var i: usize = window.start;
    while (i < window.end) : (i += 1) {
        if (buffer.items[i] == '{') count += 1;
        if (buffer.items[i] == '}') count -= 1;
        if (count == 0) return i;
    }

    return null;
}

fn getFirstClassWindow(window: Window, buffer: *std.ArrayList(u8)) Error!Window {
    var win: Window = .{
        .start = window.start,
        .end = window.end,
    };

    if(findString(win, buffer, "class")) |s| {
        win.start = s;

        var i = s;
        while (i < win.end) : (i += 1) {
            if (buffer.items[i] == '{') {
                win.start = i;
                if (findClosingBracket(win, buffer)) |end| {
                    var j = s;
                    while (j >= window.start) : (j -= 1) {
                        if (buffer.items[j] == '\n') {
                            win.start = j + 1;
                            break;
                        }
                    }
                    win.end = end + 1;
                    return win;
                }
                return Error.ClassNotFound;
            }
        }
        return Error.PropertyNotFound;

    } else return Error.ClassNotFound;
}

fn getClassWindow(window: Window, buffer: *std.ArrayList(u8), identifier: []const u8, allocator: std.mem.Allocator) Error!Window {
    var win: Window = .{
        .start = window.start,
        .end = window.end,
    };

    const class_def = std.fmt.allocPrint(allocator, "class {s}", .{identifier}) catch return Error.OutOfMemory;
    defer allocator.free(class_def);

    while (true) {
        if (findString(win, buffer, class_def)) |s| {
            var i = s;
            while (i < win.end) : (i += 1) {
                if (buffer.items[i] == '{') {
                    win.start = i;
                    if (findClosingBracket(win, buffer)) |end| {
                        var j = s;
                        while (j >= window.start) : (j -= 1) {
                            if (buffer.items[j] == '\n') {
                                win.start = j + 1;
                                break;
                            }
                        }

                        win.end = end + 1;
                        return win;
                    }
                    return Error.ClassNotFound;
                }
            }
            return Error.ClassNotFound;
        } else {
            return Error.ClassNotFound;
        }
    }
}

fn getPropertyWindow(window: Window, buffer: *std.ArrayList(u8), identifier: []const u8, allocator: std.mem.Allocator) Error!Window {
    var win: Window = .{
        .start = window.start,
        .end = window.end,
    };

    const property_def = std.fmt.allocPrint(allocator, "{s} =", .{identifier}) catch return Error.OutOfMemory;
    const property_def_nospace = std.fmt.allocPrint(allocator, "{s}=", .{identifier}) catch return Error.OutOfMemory;
    defer allocator.free(property_def);
    defer allocator.free(property_def_nospace);

    const start = findString(win, buffer, property_def) orelse findString(win, buffer, property_def_nospace);

    if (start) |s| {
        var i = s;
        while (i < win.end) : (i += 1) {
            if (buffer.items[i] == ';') {
                win.start = i;
                var j = s;

                while (j >= window.start) : (j -= 1) {
                    if (buffer.items[j] == '\n') {
                        win.start = j + 1;
                        break;
                    }
                }

                win.end = i + 1;
                return win;
            }
        }
        return Error.PropertyNotFound;
    } else {
        return Error.PropertyNotFound;
    }
}

fn getEnumWindow(window: Window, buffer: *std.ArrayList(u8), identifier: []const u8, allocator: std.mem.Allocator) Error!Window {
    var win: Window = .{
        .start = window.start,
        .end = window.end,
    };

    const enum_def = std.fmt.allocPrint(allocator, "enum {s}", .{identifier}) catch return Error.OutOfMemory;
    defer allocator.free(enum_def);

    while (true) {
        if (findString(win, buffer, enum_def)) |s| {
            var i = s;
            while (i < win.end) : (i += 1) {
                if (buffer.items[i] == '{') {
                    win.start = i;
                    if (findClosingBracket(win, buffer)) |end| {
                        var j = s;
                        while (j >= window.start) : (j -= 1) {
                            if (buffer.items[j] == '\n') {
                                win.start = j + 1;
                                break;
                            }
                        }

                        win.end = end + 1;
                        return win;
                    }
                    return Error.EnumNotFound;
                }
            }
            return Error.EnumNotFound;
        } else {
            return Error.EnumNotFound;
        }
    }
}

fn getFunctionWindow(window: Window, buffer: *std.ArrayList(u8), identifier: []const u8, allocator: std.mem.Allocator) Error!Window {
    var win: Window = .{
        .start = window.start,
        .end = window.end,
    };

    const function_def = std.fmt.allocPrint(allocator, "{s}(", .{identifier}) catch return Error.OutOfMemory;
    defer allocator.free(function_def);

    while (true) {
        if (findString(win, buffer, function_def)) |s| {
            var i = s;

            while (i < win.end) : (i += 1) {
                if (buffer.items[i] == '{') {
                    win.start = i;
                    if (findClosingBracket(win, buffer)) |end| {
                        var j = s;
                        while (j >= window.start) : (j -= 1) {
                            if (buffer.items[j] == '\n') {
                                win.start = j + 1;
                                break;
                            }
                        }

                        win.end = end + 1;
                        return win;
                    }
                    return Error.FunctionNotFound;
                }

                if (buffer.items[i] == ';') {
                    break;
                }
            }

            win.start = s + 1;
        } else {
            return Error.FunctionNotFound;
        }
    }
}
