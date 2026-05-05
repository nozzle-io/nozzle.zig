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
    platform_sources: []const []const u8,
    frameworks: []const []const u8,
    system_libs: []const []const u8,
    link_libcpp: bool,
};

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
            .platform_sources = &.{
                nozzle_dir ++ "/src/backends/metal/metal_backend.mm",
                nozzle_dir ++ "/src/backends/metal/metal_texture.mm",
                nozzle_dir ++ "/src/backends/metal/metal_channel_swap.mm",
                nozzle_dir ++ "/src/backends/metal/metal_sync.mm",
                nozzle_dir ++ "/src/common/channel_swizzle_vimage.cpp",
                nozzle_dir ++ "/src/common/format_convert_vimage.cpp",
                nozzle_dir ++ "/src/backends/opengl/opengl_backend.cpp",
            },
            .frameworks = &.{ "Metal", "IOSurface", "Foundation", "Accelerate", "OpenGL" },
            .system_libs = &.{},
            .link_libcpp = true,
        },
        .windows => PlatformConfig{
            .defines = &.{ "-DNOZZLE_PLATFORM_WINDOWS=1", "-DNOZZLE_HAS_D3D11=1", "-DNOZZLE_HAS_OPENGL=1" },
            .platform_sources = &.{
                nozzle_dir ++ "/src/backends/d3d11/d3d11_backend.cpp",
                nozzle_dir ++ "/src/backends/d3d11/d3d11_texture.cpp",
                nozzle_dir ++ "/src/backends/d3d11/d3d11_sync.cpp",
                nozzle_dir ++ "/src/backends/opengl/opengl_backend.cpp",
            },
            .frameworks = &.{},
            .system_libs = &.{ "d3d11", "dxgi", "opengl32", "bcrypt" },
            .link_libcpp = false,
        },
        .linux => PlatformConfig{
            .defines = &.{ "-DNOZZLE_PLATFORM_LINUX=1", "-DNOZZLE_HAS_DMA_BUF=1", "-DNOZZLE_HAS_OPENGL=1" },
            .platform_sources = &.{
                nozzle_dir ++ "/src/backends/linux/linux_texture.cpp",
                nozzle_dir ++ "/src/backends/opengl/opengl_backend.cpp",
            },
            .frameworks = &.{},
            .system_libs = &.{ "drm", "gbm", "EGL", "GL" },
            .link_libcpp = true,
        },
        else => PlatformConfig{
            .defines = &.{},
            .platform_sources = &.{},
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

    const common_files = &[_][]const u8{
        nozzle_dir ++ "/src/common/ipc.cpp",
        nozzle_dir ++ "/src/common/registry.cpp",
        nozzle_dir ++ "/src/common/sender.cpp",
        nozzle_dir ++ "/src/common/receiver.cpp",
        nozzle_dir ++ "/src/common/frame.cpp",
        nozzle_dir ++ "/src/common/texture.cpp",
        nozzle_dir ++ "/src/common/device.cpp",
        nozzle_dir ++ "/src/common/discovery.cpp",
        nozzle_dir ++ "/src/common/metadata.cpp",
        nozzle_dir ++ "/src/common/pixel_access.cpp",
        nozzle_dir ++ "/src/common/channel_swizzle.cpp",
        nozzle_dir ++ "/src/common/format_convert.cpp",
        nozzle_dir ++ "/src/common/format_convert_sse2.cpp",
        nozzle_dir ++ "/src/common/format_convert_neon.cpp",
        nozzle_dir ++ "/src/common/format_resolve.cpp",
        nozzle_dir ++ "/src/c_api/nozzle_c.cpp",
    };

    // combine base_flags + platform defines into a single flags array
    var all_flags = std.ArrayList([]const u8).initCapacity(b.allocator, base_flags.len + platform.defines.len) catch unreachable;
    all_flags.appendSliceAssumeCapacity(base_flags);
    all_flags.appendSliceAssumeCapacity(platform.defines);

    lib_mod.addCSourceFiles(.{
        .files = common_files,
        .flags = all_flags.items,
    });

    if (platform.platform_sources.len > 0) {
        lib_mod.addCSourceFiles(.{
            .files = platform.platform_sources,
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
