const std = @import("std");

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

    const csharp_bind_module = b.createModule(.{
        .root_source_file = b.path("bind/bind.zig"),
        .link_libcpp = true,
        .target = target,
        .optimize = optimise,
    });
    csharp_bind_module.addImport("modlib", root_module);

    csharp_bind_module.addCSourceFile(.{
        .file = b.path(".out/wrap/csharp/haze_mod_lib_wrap.cxx"),
        .flags = &.{ "-std=c++23" },
    });

    csharp_bind_module.addIncludePath(b.path("bind/"));

    const csharp_dll = b.addLibrary(.{
        .name = "haze_mod_lib_csharp",
        .linkage = .dynamic,
        .root_module = csharp_bind_module,
    });

    const csharp_bind_artifact = b.addInstallArtifact(csharp_dll, .{});

    const python_bind_module = b.createModule(.{
        .root_source_file = b.path("bind/bind.zig"),
        .link_libcpp = true,
        .target = target,
        .optimize = optimise,
    });
    python_bind_module.addImport("modlib", root_module);

    python_bind_module.addCSourceFile(.{
        .file = b.path(".out/wrap/python/haze_mod_lib_wrap.cxx"),
        .flags = &.{ "-std=c++23" },
    });

    python_bind_module.addIncludePath(b.path("bind/"));
    python_bind_module.addIncludePath(b.path("bind/include/python/headers/"));
    python_bind_module.addLibraryPath(b.path("bind/include/python/libs/"));

    python_bind_module.linkSystemLibrary("python314", .{
        .preferred_link_mode = .static,
    });

    const python_dll = b.addLibrary(.{
        .name = "haze_mod_lib_python",
        .linkage = .dynamic,
        .root_module = python_bind_module,
    });

    const python_bind_artifact = b.addInstallArtifact(python_dll, .{});

    const go_bind_module = b.createModule(.{
        .root_source_file = b.path("bind/bind.zig"),
        .link_libcpp = true,
        .target = target,
        .optimize = optimise,
    });
    go_bind_module.addImport("modlib", root_module);

    go_bind_module.addCSourceFile(.{
        .file = b.path(".out/wrap/csharp/haze_mod_lib_wrap.cxx"),
        .flags = &.{ "-std=c++23" },
    });

    go_bind_module.addIncludePath(b.path("bind/"));

    const go_dll = b.addLibrary(.{
        .name = "haze_mod_lib_go",
        .linkage = .dynamic,
        .root_module = go_bind_module,
    });

    const go_bind_artifact = b.addInstallArtifact(go_dll, .{});

    release_step.dependOn(&java_bind_artifact.step);
    release_step.dependOn(&csharp_bind_artifact.step);
    release_step.dependOn(&python_bind_artifact.step);
    release_step.dependOn(&go_bind_artifact.step);
}
