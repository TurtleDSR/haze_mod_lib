pub const zip = @import("zip");
pub const lexer = @import("lexer/lexer.zig");
pub const modlib = @import("handle/modlib.zig");
pub const mod = @import("handle/mod.zig");

//structs
pub const ModLib = modlib.ModLib;
pub const Mod = mod.Mod;

pub const Keyword = enum {
    //operations
    open,
    import,
    patch,
    add,
    end,
    comment,

    //scope
    GLOBAL,
    AUTO,
    CLASS,
    FUNCTION,
    PROPERTY,
    ENUM,

    //misc
    _text, //can either be angelscript or plain text, implied by context.
    _newline, //used to maintain code readability and as compile-ability
    _null, //no-op, used as a default value for the token struct.
};

pub const InjectorError = error{
    Success, //should never be returned
    FileNotFound,
    FileOpenFailure,
    FileReadError,
    FileWriteError,
    UnknownError,
    OutOfMemory,
    MissingDependency,
    ThreadingError,
    SyntaxError,

    ClassNotFound,
    FunctionNotFound,
    PropertyNotFound,
    EnumNotFound,
};

pub const InjectorErrorCode = enum(u8) {
    Success = 0,
    FileNotFound = 1,
    FileOpenFailure = 2,
    FileReadError = 3,
    FileWriteError = 4,
    UnknownError = 5,
    OutOfMemory = 6,
    MissingDependency = 7,
    ThreadingError = 8,
    SyntaxError = 9,

    ClassNotFound = 10,
    FunctionNotFound = 11,
    PropertyNotFound = 12,
    EnumNotFound = 13,

    pub fn errorFromCode(code: InjectorErrorCode) InjectorError {
        return switch (code) {
            InjectorErrorCode.FileNotFound => InjectorError.FileNotFound,
            InjectorErrorCode.FileOpenFailure => InjectorError.FileOpenFailure,
            InjectorErrorCode.FileReadError => InjectorError.FileReadError,
            InjectorErrorCode.FileWriteError => InjectorError.FileWriteError,
            InjectorErrorCode.UnknownError => InjectorError.UnknownError,
            InjectorErrorCode.OutOfMemory => InjectorError.OutOfMemory,
            InjectorErrorCode.MissingDependency => InjectorError.MissingDependency,
            InjectorErrorCode.ThreadingError => InjectorError.ThreadingError,
            InjectorErrorCode.SyntaxError => InjectorError.SyntaxError,
            InjectorErrorCode.ClassNotFound => InjectorError.ClassNotFound,
            InjectorErrorCode.FunctionNotFound => InjectorError.FunctionNotFound,
            InjectorErrorCode.PropertyNotFound => InjectorError.PropertyNotFound,
            InjectorErrorCode.EnumNotFound => InjectorError.EnumNotFound,
            InjectorErrorCode.Success => InjectorError.Success,
        };
    }

    pub fn codeFromError(code: InjectorError) InjectorErrorCode {
        return switch (code) {
            InjectorError.FileNotFound => InjectorErrorCode.FileNotFound,
            InjectorError.FileOpenFailure => InjectorErrorCode.FileOpenFailure,
            InjectorError.FileReadError => InjectorErrorCode.FileReadError,
            InjectorError.FileWriteError => InjectorErrorCode.FileWriteError,
            InjectorError.UnknownError => InjectorErrorCode.UnknownError,
            InjectorError.OutOfMemory => InjectorErrorCode.OutOfMemory,
            InjectorError.MissingDependency => InjectorErrorCode.MissingDependency,
            InjectorError.ThreadingError => InjectorErrorCode.ThreadingError,
            InjectorError.SyntaxError => InjectorErrorCode.SyntaxError,
            InjectorError.ClassNotFound => InjectorErrorCode.ClassNotFound,
            InjectorError.FunctionNotFound => InjectorErrorCode.FunctionNotFound,
            InjectorError.PropertyNotFound => InjectorErrorCode.PropertyNotFound,
            InjectorError.EnumNotFound => InjectorErrorCode.EnumNotFound,
            InjectorError.Success => InjectorErrorCode.Success,
        };
    }
};

pub const ModHandleError = error{
    FileNotFound,
    FileOpenFailure,
    FileReadError,
    FileWriteError,
    PropertiesOpenError,
    PropertiesReadError,
    PropertiesParseError,
    UnknownError,
    OutOfMemoryError,
};

pub const ModFormat = enum {
    HAZEMOD,
    ZIP,
};
