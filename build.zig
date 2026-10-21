const std = @import("std");
const zlinter = @import("zlinter");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimise = b.standardOptimizeOption(.{});

    //dependencies
    const zip = b.dependency("zip", .{});

    //common
    const common_module = b.createModule(.{
        .root_source_file = b.path("src/common.zig"),
        .target = target,
        .optimize = optimise,
    });
    common_module.addImport("zip", zip.module("zip"));

    //root
    const root_module = b.addModule("modlib", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimise,
    });
    root_module.addImport("common", common_module);

    //test step
    const test_module = b.createModule(.{
        .root_source_file = b.path("test/tests.zig"),
        .target = target,
        .optimize = optimise,
    });
    test_module.addImport("modlib", root_module);
    test_module.addImport("common", common_module);

    const tests = b.addTest(.{
        .root_module = test_module,
    });

    const test_artifact = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run Tests");
    test_step.dependOn(&test_artifact.step);

    //lint step
    const lint_cmd = b.step("lint", "Lint source code.");
    lint_cmd.dependOn(step: {
        var builder = zlinter.builder(b, .{});
        builder.addRule(.{ .builtin = .function_naming }, .{});
        builder.addRule(.{ .builtin = .file_naming }, .{});
        builder.addRule(.{ .builtin = .switch_case_ordering }, .{});
        builder.addRule(.{ .builtin = .no_unused }, .{});
        builder.addRule(.{ .builtin = .no_deprecated }, .{});
        builder.addRule(.{ .builtin = .no_orelse_unreachable }, .{});
        break :step builder.build();
    });

    //bind step
    const bind_module = b.createModule(.{
        .root_source_file = b.path("bind/bind.zig"),
        .target = target,
        .optimize = optimise,
    });
    bind_module.addImport("modlib", root_module);

    const bind_lib_dynamic = b.addLibrary(.{
        .name = "haze_mod_lib",
        .linkage = .dynamic,
        .root_module = bind_module,
    });

    const bind_lib_static = b.addLibrary(.{
        .name = "haze_mod_lib_static",
        .linkage = .static,
        .root_module = bind_module,
    });

    const bind_dynamic_artifact = b.addInstallArtifact(bind_lib_dynamic, .{});
    const bind_static_artifact = b.addInstallArtifact(bind_lib_static, .{});

    const bind_step = b.step("bind", "Generate bindings.");
    bind_step.dependOn(&bind_dynamic_artifact.step);
    bind_step.dependOn(&bind_static_artifact.step);

    const release_step = b.step("release", "Compile Bindings");

    const java_bind_module = b.createModule(.{
        .root_source_file = b.path("bind/bind.zig"),
        .link_libcpp = true,
        .target = target,
        .optimize = optimise,
    });
    java_bind_module.addImport("modlib", root_module);

    java_bind_module.addCSourceFile(.{
        .file = b.path(".out/wrap/java/haze_mod_lib_wrap.cxx"),
        .flags = &.{ "-std=c++23" },
    });

    java_bind_module.addIncludePath(b.path("bind/include/jni/"));
    java_bind_module.addIncludePath(b.path("bind/"));

    const java_dll = b.addLibrary(.{
        .name = "haze_mod_lib_java",
        .linkage = .dynamic,
        .root_module = java_bind_module,
    });

    const java_bind_artifact = b.addInstallArtifact(java_dll, .{});

    release_step.dependOn(&java_bind_artifact.step);
}
