const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nozzle_lib = buildNozzle(b, target, optimize);

    // nozzle module for @import("nozzle")
    const nozzle_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    nozzle_mod.linkLibrary(nozzle_lib);

    // examples
    const examples = .{
        "sender",
        "receiver",
    };
    inline for (examples) |name| {
        const exe_mod = b.createModule(.{
            .root_source_file = b.path("examples/" ++ name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });
        exe_mod.addImport("nozzle", nozzle_mod);
        const exe = b.addExecutable(.{
            .name = "nozzle-" ++ name,
            .root_module = exe_mod,
        });
        b.installArtifact(exe);
    }

    // tests
    const test_mod = b.createModule(.{
        .root_source_file = b.path("tests/unit.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_mod.addImport("nozzle", nozzle_mod);
    const unit_tests = b.addTest(.{
        .root_module = test_mod,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

const PlatformConfig = struct {
    defines: []const []const u8,
    source_lists: []const []const u8,
    frameworks: []const []const u8,
    system_libs: []const []const u8,
    link_libcpp: bool,
};

fn readSourceList(b: *std.Build, nozzle_dir: []const u8, group: []const u8) []const []const u8 {
    const list_path = b.fmt("{s}/sources/{s}.txt", .{ nozzle_dir, group });
    const contents = b.build_root.handle.readFileAlloc(b.allocator, list_path, 64 * 1024) catch |err| {
        std.debug.panic("could not read {s}: {s}", .{ list_path, @errorName(err) });
    };
    var files = std.ArrayList([]const u8).init(b.allocator);
    var lines = std.mem.tokenizeAny(u8, contents, "\r\n");
    while (lines.next()) |line| {
        files.append(b.fmt("{s}/{s}", .{ nozzle_dir, line })) catch @panic("OOM");
    }
    if (files.items.len == 0) {
        std.debug.panic("{s} is empty", .{list_path});
    }
    return files.items;
}

fn buildNozzle(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const nozzle_dir = "deps/nozzle";
    const plog_dir = nozzle_dir ++ "/libs/plog/include";

    const os_tag = target.result.os.tag;

    const platform = switch (os_tag) {
        .macos => PlatformConfig{
            .defines = &.{ "-DNOZZLE_PLATFORM_MACOS=1", "-DNOZZLE_HAS_METAL=1", "-DNOZZLE_HAS_OPENGL=1" },
            .source_lists = &.{ "macos", "opengl" },
            .frameworks = &.{ "Metal", "IOSurface", "Foundation", "Accelerate", "OpenGL" },
            .system_libs = &.{},
            .link_libcpp = true,
        },
        .windows => PlatformConfig{
            .defines = &.{ "-DNOZZLE_PLATFORM_WINDOWS=1", "-DNOZZLE_HAS_D3D11=1", "-DNOZZLE_HAS_OPENGL=1" },
            .source_lists = &.{ "windows", "opengl" },
            .frameworks = &.{},
            .system_libs = &.{ "d3d11", "dxgi", "opengl32", "bcrypt" },
            .link_libcpp = true,
        },
        .linux => PlatformConfig{
            .defines = &.{ "-DNOZZLE_PLATFORM_LINUX=1", "-DNOZZLE_HAS_DMA_BUF=1", "-DNOZZLE_HAS_OPENGL=1" },
            .source_lists = &.{ "linux", "opengl" },
            .frameworks = &.{},
            .system_libs = &.{ "drm", "gbm", "EGL", "GL" },
            .link_libcpp = true,
        },
        else => PlatformConfig{
            .defines = &.{},
            .source_lists = &.{},
            .frameworks = &.{},
            .system_libs = &.{},
            .link_libcpp = true,
        },
    };

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = if (platform.link_libcpp) true else null,
    });

    const lib = b.addLibrary(.{
        .name = "nozzle",
        .linkage = .static,
        .root_module = lib_mod,
    });

    // build combined flags: base + platform defines
    const base_flags = &[_][]const u8{
        "-std=c++17",
        "-fno-exceptions",
        "-fno-rtti",
    };

    // combine base_flags + platform defines into a single flags array
    var all_flags = std.ArrayList([]const u8).initCapacity(b.allocator, base_flags.len + platform.defines.len) catch unreachable;
    all_flags.appendSliceAssumeCapacity(base_flags);
    all_flags.appendSliceAssumeCapacity(platform.defines);

    lib_mod.addCSourceFiles(.{
        .files = readSourceList(b, nozzle_dir, "common"),
        .flags = all_flags.items,
    });

    for (platform.source_lists) |group| {
        lib_mod.addCSourceFiles(.{
            .files = readSourceList(b, nozzle_dir, group),
            .flags = all_flags.items,
        });
    }

    lib_mod.addIncludePath(b.path(nozzle_dir ++ "/include"));
    lib_mod.addIncludePath(b.path(nozzle_dir ++ "/src"));
    lib_mod.addIncludePath(b.path(plog_dir));

    for (platform.frameworks) |fw| {
        lib_mod.linkFramework(fw, .{});
    }

    for (platform.system_libs) |lib_name| {
        lib_mod.linkSystemLibrary(lib_name, .{});
    }

    lib.installHeader(b.path(nozzle_dir ++ "/include/nozzle/nozzle_c.h"), "nozzle/nozzle_c.h");

    return lib;
}
