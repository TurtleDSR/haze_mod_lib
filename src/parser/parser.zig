const std = @import("std");
const common = @import("../common.zig");
const scriptedit = @import("../parser/scriptedit.zig");
const lexer = common.lexer;

const Token = @import("../lexer/token.zig").Token;

const InjectorError = common.InjectorError;
const Keyword = common.Keyword;

const ScriptEdit = scriptedit.ScriptEdit;

pub fn streamEdits(file: []const u8, data: []const u8, queue: *std.Io.Queue(*ScriptEdit), queue_size: *std.atomic.Value(u8), allocator: std.mem.Allocator, io: std.Io) InjectorError!void {
    var tokens = lexer.getTokens(data, allocator) catch |err| {
        return switch (err) {
            lexer.Error.OutOfMemory => InjectorError.OutOfMemory,
            lexer.Error.UnknownKeyword => InjectorError.SyntaxError,
        };
    };

    defer { //free tokens
        for (tokens.items) |t| {
            allocator.free(t.data);
        }
        tokens.deinit(allocator);
    }

    var opened_script_file: []const u8 = "";
    defer if (opened_script_file.len > 0) allocator.free(opened_script_file);

    var script_file_is_opened = false;

    var i: usize = 0;

    var override_edit: ScriptEdit = .{ //edit queued to replace/add current .as file
        .file = allocator.dupe(u8, file) catch return InjectorError.OutOfMemory,
        .operation = .REPLACE,
        .target = .{ .scope = .GLOBAL },
    };

    errdefer override_edit.deinit(allocator);

    while (i < tokens.items.len) : (i += 1) {
        var token = tokens.items[i];

        switch (token.keyword) {
            Keyword.open => {
                i += 1;
                if (i + 1 >= tokens.items.len) return InjectorError.SyntaxError;
                token = tokens.items[i];

                if (token.keyword != Keyword._text) return InjectorError.SyntaxError;

                const new_script_file = allocator.dupe(u8, token.data) catch return InjectorError.OutOfMemory;

                if (opened_script_file.len > 0) {
                    allocator.free(opened_script_file);
                }

                opened_script_file = new_script_file;
                script_file_is_opened = true;

                while (i < tokens.items.len and token.keyword != Keyword._newline) : (i += 1) { //skip to next line
                    token = tokens.items[i];
                }
                i -= 1;
            },

            Keyword.import => {
                if (!script_file_is_opened) return InjectorError.SyntaxError;

                var import_tokens: std.ArrayList([]const u8) = .empty;
                defer import_tokens.clearAndFree(allocator);

                i += 1;
                if (i + 1 >= tokens.items.len) return InjectorError.SyntaxError;
                token = tokens.items[i];

                import_tokens.append(allocator, "import ") catch return InjectorError.OutOfMemory;
                import_tokens.append(allocator, token.data) catch return InjectorError.OutOfMemory;
                import_tokens.append(allocator, ";") catch return InjectorError.OutOfMemory;

                const import_statement = std.mem.concat(allocator, u8, import_tokens.items) catch return InjectorError.OutOfMemory;
                errdefer allocator.free(import_statement);

                var edit: ScriptEdit = .{};

                edit.operation = .ADD;
                edit.target = .{
                    .scope = .IMPORT,
                };
                edit.file = allocator.dupe(u8, opened_script_file) catch return InjectorError.OutOfMemory;
                errdefer allocator.free(edit.file);

                edit.data = import_statement;

                const submit_edit = allocator.create(ScriptEdit) catch return InjectorError.OutOfMemory;
                submit_edit.* = edit;

                queue.putOne(io, submit_edit) catch {
                    submit_edit.deinit(allocator);
                    allocator.destroy(submit_edit);
                    return InjectorError.ThreadingError;
                };
                _ = queue_size.fetchAdd(1, .release);

                while (i < tokens.items.len and token.keyword != Keyword._newline) : (i += 1) { //skip to next line
                    token = tokens.items[i];
                }
                i -= 1;
            },

            Keyword.patch => {
                if (!script_file_is_opened) return InjectorError.SyntaxError;

                i += 1;
                if (i + 1 >= tokens.items.len) return InjectorError.SyntaxError;
                token = tokens.items[i];

                var edit: ScriptEdit = .{};

                edit.file = allocator.dupe(u8, opened_script_file) catch return InjectorError.OutOfMemory;
                errdefer allocator.free(edit.file);

                edit.operation = .REPLACE;
                edit.target = .{};

                edit.target.scope = switch (token.keyword) {
                    Keyword.GLOBAL => scriptedit.Scope.GLOBAL,
                    Keyword.AUTO => scriptedit.Scope.AUTO,
                    Keyword._text => scriptedit.Scope.CLASS,

                    else => return InjectorError.SyntaxError,
                };

                if (edit.target.scope == .CLASS) { //get class identifier
                    edit.target.identifier = allocator.dupe(u8, token.data) catch return InjectorError.OutOfMemory;
                }
                errdefer if (edit.target.identifier.len > 0) {
                    allocator.free(edit.target.identifier);
                };

                const sub_target = allocator.create(scriptedit.Target) catch return InjectorError.OutOfMemory;
                sub_target.* = .{};
                errdefer allocator.destroy(sub_target);

                edit.target.target = sub_target;

                i += 1;
                if (i + 1 >= tokens.items.len) return InjectorError.SyntaxError;
                token = tokens.items[i];

                edit.target.target.?.scope = switch (token.keyword) {
                    Keyword.FUNCTION => scriptedit.Scope.FUNCTION,
                    Keyword.PROPERTY => scriptedit.Scope.PROPERTY,
                    Keyword.ENUM => scriptedit.Scope.ENUM,
                    Keyword.CLASS => scriptedit.Scope.CLASS,

                    else => return InjectorError.SyntaxError,
                };

                i += 1;
                if (i + 1 >= tokens.items.len) return InjectorError.SyntaxError;
                token = tokens.items[i];
                edit.target.target.?.identifier = allocator.dupe(u8, token.data) catch return InjectorError.OutOfMemory;
                errdefer if (edit.target.target.?.identifier.len > 0) {
                    allocator.free(edit.target.identifier);
                };

                while (i < tokens.items.len and token.keyword != Keyword._newline) : (i += 1) { //skip to next line
                    token = tokens.items[i];
                }
                i -= 1;

                i += 1;
                if (i + 1 >= tokens.items.len) return InjectorError.SyntaxError;
                while (i < tokens.items.len) : (i += 1) {
                    token = tokens.items[i];
                    if (token.keyword == Keyword.end) break;

                    const new_data = std.fmt.allocPrint(allocator, "{s} {s}", .{ edit.data, token.data }) catch return InjectorError.OutOfMemory;
                    errdefer allocator.free(new_data);
                    allocator.free(edit.data);

                    edit.data = new_data;
                } else if (token.keyword != Keyword.end) { //tokens ran out, return syntax error
                    return InjectorError.SyntaxError;
                }

                const submit_edit = allocator.create(ScriptEdit) catch return InjectorError.OutOfMemory;
                submit_edit.* = edit;

                queue.putOne(io, submit_edit) catch {
                    submit_edit.deinit(allocator);
                    allocator.destroy(submit_edit);
                    return InjectorError.ThreadingError;
                };
                _ = queue_size.fetchAdd(1, .release);

                while (i < tokens.items.len and token.keyword != Keyword._newline) : (i += 1) { //skip to next line
                    token = tokens.items[i];
                }
                i -= 1;
            },

            Keyword.add => {
                if (!script_file_is_opened) return InjectorError.SyntaxError;

                i += 1;
                if (i + 1 >= tokens.items.len) return InjectorError.SyntaxError;
                token = tokens.items[i];

                var edit: ScriptEdit = .{};

                edit.file = allocator.dupe(u8, opened_script_file) catch return InjectorError.OutOfMemory;
                errdefer allocator.free(edit.file);

                edit.operation = .ADD;

                edit.target.scope = switch (token.keyword) {
                    Keyword.GLOBAL => scriptedit.Scope.GLOBAL,
                    Keyword.AUTO => scriptedit.Scope.AUTO,
                    Keyword._text => scriptedit.Scope.CLASS,

                    else => return InjectorError.SyntaxError,
                };

                if (edit.target.scope == .CLASS) { //get class identifier
                    edit.target.identifier = allocator.dupe(u8, token.data) catch return InjectorError.OutOfMemory;
                }
                errdefer if (edit.target.identifier.len > 0) {
                    allocator.free(edit.target.identifier);
                };

                const sub_target = allocator.create(scriptedit.Target) catch return InjectorError.OutOfMemory;
                sub_target.* = .{};
                errdefer allocator.destroy(sub_target);

                edit.target.target = sub_target;

                i += 1;
                if (i + 1 >= tokens.items.len) return InjectorError.SyntaxError;
                token = tokens.items[i];

                edit.target.target.?.scope = switch (token.keyword) {
                    Keyword.FUNCTION => scriptedit.Scope.FUNCTION,
                    Keyword.PROPERTY => scriptedit.Scope.PROPERTY,
                    Keyword.ENUM => scriptedit.Scope.ENUM,
                    Keyword.CLASS => scriptedit.Scope.CLASS,

                    else => return InjectorError.SyntaxError,
                };

                i += 1;
                if (i + 1 >= tokens.items.len) return InjectorError.SyntaxError;
                while (i < tokens.items.len) : (i += 1) {
                    token = tokens.items[i];

                    if (token.keyword == Keyword.end) break;

                    const new_data = std.fmt.allocPrint(allocator, "{s} {s}", .{ edit.data, token.data }) catch return InjectorError.OutOfMemory;
                    errdefer allocator.free(new_data);
                    allocator.free(edit.data);

                    edit.data = new_data;
                } else if (token.keyword != Keyword.end) { //tokens ran out, return syntax error
                    return InjectorError.SyntaxError;
                }

                const submit_edit = allocator.create(ScriptEdit) catch return InjectorError.OutOfMemory;
                submit_edit.* = edit;

                queue.putOne(io, submit_edit) catch {
                    submit_edit.deinit(allocator);
                    allocator.destroy(submit_edit);
                    return InjectorError.ThreadingError;
                };
                _ = queue_size.fetchAdd(1, .release);

                while (i < tokens.items.len and token.keyword != Keyword._newline) : (i += 1) { //skip to next line
                    token = tokens.items[i];
                }
                i -= 1;
            },

            Keyword.comment => {
                while (i < tokens.items.len and token.keyword != Keyword._newline) : (i += 1) { //skip to next line
                    token = tokens.items[i];
                }
                i -= 1;
            },

            Keyword._text => {
                while (i < tokens.items.len) : (i += 1) {
                    token = tokens.items[i];
                    if(tokenIsFunctionalKeyword(token)) break;

                    const new_data = std.fmt.allocPrint(allocator, "{s} {s}", .{ override_edit.data, token.data }) catch return InjectorError.OutOfMemory;
                    errdefer allocator.free(new_data);

                    allocator.free(override_edit.data);

                    override_edit.data = new_data;
                }
            },

            Keyword._newline => {
                //skip token
            },

            else => {
                if (!tokenIsFunctionalKeyword(token)) { //token got mistakenly lexed as parameter instead of text - assumed
                    tokens.items[i].keyword = ._text;
                    i -= 1; //retry token
                    continue;
                }
                return InjectorError.SyntaxError;
            },
        }
    }

    //push remaining override edit
    if (override_edit.data.len != 0) {
        const edit_ptr = allocator.create(ScriptEdit) catch {
            override_edit.deinit(allocator);
            return InjectorError.OutOfMemory;
        };
        edit_ptr.* = override_edit;

        queue.putOne(io, edit_ptr) catch {
            edit_ptr.deinit(allocator);
            allocator.destroy(edit_ptr);
            return InjectorError.ThreadingError;
        };
        _ = queue_size.fetchAdd(1, .release);
    } else {
        override_edit.deinit(allocator);
    }
}

pub fn tokenIsFunctionalKeyword(tkn: Token) bool {
    return switch (tkn.keyword) {
        Keyword.open => true,
        Keyword.import => true,
        Keyword.patch => true,
        Keyword.add => true,

        else => false,
    };
}
