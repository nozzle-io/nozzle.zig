const std = @import("std");
const nozzle = @import("nozzle");

// ============================================================================
// Pure Zig logic tests (no GPU required, always run)
// ============================================================================

test "texture format bytes_per_pixel covers all variants" {
    // Every non-unknown format must return a non-null value
    const formats = [_]nozzle.TextureFormat{
        .r8_unorm,     .rg8_unorm,     .rgba8_unorm,
        .bgra8_unorm,  .rgba8_srgb,    .bgra8_srgb,
        .r16_unorm,    .rg16_unorm,    .rgba16_unorm,
        .r16_float,    .rg16_float,    .rgba16_float,
        .r32_float,    .rg32_float,    .rgba32_float,
        .r32_uint,     .rgba32_uint,   .depth32_float,
    };
    for (formats) |fmt| {
        const bpp = fmt.bytesPerPixel();
        try std.testing.expect(bpp != null);
        try std.testing.expect(bpp.? > 0);
    }
    // unknown returns null
    try std.testing.expect(nozzle.TextureFormat.unknown.bytesPerPixel() == null);
}

test "texture format bytes_per_pixel correctness" {
    // 8-bit: 1 byte per pixel
    try std.testing.expectEqual(@as(u8, 1), nozzle.TextureFormat.r8_unorm.bytesPerPixel().?);

    // 8-bit 2-channel: 2 bpp
    try std.testing.expectEqual(@as(u8, 2), nozzle.TextureFormat.rg8_unorm.bytesPerPixel().?);

    // 8-bit 4-channel: 4 bpp
    try std.testing.expectEqual(@as(u8, 4), nozzle.TextureFormat.rgba8_unorm.bytesPerPixel().?);
    try std.testing.expectEqual(@as(u8, 4), nozzle.TextureFormat.bgra8_unorm.bytesPerPixel().?);
    try std.testing.expectEqual(@as(u8, 4), nozzle.TextureFormat.rgba8_srgb.bytesPerPixel().?);
    try std.testing.expectEqual(@as(u8, 4), nozzle.TextureFormat.bgra8_srgb.bytesPerPixel().?);

    // 16-bit 1-channel: 2 bpp
    try std.testing.expectEqual(@as(u8, 2), nozzle.TextureFormat.r16_unorm.bytesPerPixel().?);
    try std.testing.expectEqual(@as(u8, 2), nozzle.TextureFormat.r16_float.bytesPerPixel().?);

    // 16-bit 2-channel: 4 bpp
    try std.testing.expectEqual(@as(u8, 4), nozzle.TextureFormat.rg16_unorm.bytesPerPixel().?);
    try std.testing.expectEqual(@as(u8, 4), nozzle.TextureFormat.rg16_float.bytesPerPixel().?);

    // 16-bit 4-channel: 8 bpp
    try std.testing.expectEqual(@as(u8, 8), nozzle.TextureFormat.rgba16_unorm.bytesPerPixel().?);
    try std.testing.expectEqual(@as(u8, 8), nozzle.TextureFormat.rgba16_float.bytesPerPixel().?);

    // 32-bit 1-channel: 4 bpp
    try std.testing.expectEqual(@as(u8, 4), nozzle.TextureFormat.r32_float.bytesPerPixel().?);
    try std.testing.expectEqual(@as(u8, 4), nozzle.TextureFormat.r32_uint.bytesPerPixel().?);
    try std.testing.expectEqual(@as(u8, 4), nozzle.TextureFormat.depth32_float.bytesPerPixel().?);

    // 32-bit 2-channel: 8 bpp
    try std.testing.expectEqual(@as(u8, 8), nozzle.TextureFormat.rg32_float.bytesPerPixel().?);

    // 32-bit 4-channel: 16 bpp
    try std.testing.expectEqual(@as(u8, 16), nozzle.TextureFormat.rgba32_float.bytesPerPixel().?);
    try std.testing.expectEqual(@as(u8, 16), nozzle.TextureFormat.rgba32_uint.bytesPerPixel().?);
}

test "error code mapping covers all C error codes" {
    try std.testing.expectError(error.Unknown, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_UNKNOWN));
    try std.testing.expectError(error.InvalidArgument, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_INVALID_ARGUMENT));
    try std.testing.expectError(error.UnsupportedBackend, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_UNSUPPORTED_BACKEND));
    try std.testing.expectError(error.UnsupportedFormat, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_UNSUPPORTED_FORMAT));
    try std.testing.expectError(error.DeviceMismatch, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_DEVICE_MISMATCH));
    try std.testing.expectError(error.ResourceCreationFailed, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_RESOURCE_CREATION_FAILED));
    try std.testing.expectError(error.SharedHandleFailed, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_SHARED_HANDLE_FAILED));
    try std.testing.expectError(error.SenderNotFound, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_SENDER_NOT_FOUND));
    try std.testing.expectError(error.SenderClosed, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_SENDER_CLOSED));
    try std.testing.expectError(error.Timeout, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_TIMEOUT));
    try std.testing.expectError(error.BackendError, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_BACKEND_ERROR));
    // OK should succeed
    try nozzle.checkCode(nozzle.c.NOZZLE_OK);
}

test "backend type enum matches C values" {
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_BACKEND_UNKNOWN), @intFromEnum(nozzle.BackendType.unknown));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_BACKEND_D3D11), @intFromEnum(nozzle.BackendType.d3d11));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_BACKEND_METAL), @intFromEnum(nozzle.BackendType.metal));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_BACKEND_OPENGL), @intFromEnum(nozzle.BackendType.opengl));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_BACKEND_DMA_BUF), @intFromEnum(nozzle.BackendType.dma_buf));
}

test "texture format enum matches C values" {
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_UNKNOWN), @intFromEnum(nozzle.TextureFormat.unknown));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_R8_UNORM), @intFromEnum(nozzle.TextureFormat.r8_unorm));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_RG8_UNORM), @intFromEnum(nozzle.TextureFormat.rg8_unorm));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_RGBA8_UNORM), @intFromEnum(nozzle.TextureFormat.rgba8_unorm));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_RGBA32_FLOAT), @intFromEnum(nozzle.TextureFormat.rgba32_float));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_DEPTH32_FLOAT), @intFromEnum(nozzle.TextureFormat.depth32_float));
}

test "receive mode enum matches C values" {
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_RECEIVE_LATEST_ONLY), @intFromEnum(nozzle.ReceiveMode.latest_only));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_RECEIVE_SEQUENTIAL_BEST_EFFORT), @intFromEnum(nozzle.ReceiveMode.sequential_best_effort));
}

test "frame status enum matches C values" {
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FRAME_NEW), @intFromEnum(nozzle.FrameStatus.new));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FRAME_NO_NEW), @intFromEnum(nozzle.FrameStatus.no_new));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FRAME_DROPPED), @intFromEnum(nozzle.FrameStatus.dropped));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FRAME_SENDER_CLOSED), @intFromEnum(nozzle.FrameStatus.sender_closed));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FRAME_ERROR), @intFromEnum(nozzle.FrameStatus.err));
}

test "texture origin enum matches C values" {
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_ORIGIN_TOP_LEFT), @intFromEnum(nozzle.TextureOrigin.top_left));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_ORIGIN_BOTTOM_LEFT), @intFromEnum(nozzle.TextureOrigin.bottom_left));
}

test "format source enum matches C values" {
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_SOURCE_UNKNOWN), @intFromEnum(nozzle.FormatSource.unknown));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_SOURCE_REQUESTED), @intFromEnum(nozzle.FormatSource.requested));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_SOURCE_CALLER_HINT), @intFromEnum(nozzle.FormatSource.caller_hint));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_FORMAT_SOURCE_NATIVE_OBSERVED), @intFromEnum(nozzle.FormatSource.native_observed));
}

test "native format kind enum matches C values" {
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_NATIVE_KIND_UNKNOWN), @intFromEnum(nozzle.NativeFormatKind.unknown));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_NATIVE_KIND_MTL_PIXEL_FORMAT), @intFromEnum(nozzle.NativeFormatKind.mtl_pixel_format));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_NATIVE_KIND_DXGI_FORMAT), @intFromEnum(nozzle.NativeFormatKind.dxgi_format));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_NATIVE_KIND_DRM_FOURCC), @intFromEnum(nozzle.NativeFormatKind.drm_fourcc));
    try std.testing.expectEqual(@as(c_int, nozzle.c.NOZZLE_NATIVE_KIND_GL_INTERNAL_FORMAT), @intFromEnum(nozzle.NativeFormatKind.gl_internal_format));
}

test "sender desc defaults" {
    const desc = nozzle.SenderDesc{
        .name = "test",
        .application_name = "test",
    };
    try std.testing.expectEqual(@as(u32, 3), desc.ring_buffer_size);
    try std.testing.expectEqual(true, desc.allow_format_fallback);
}

test "receiver desc defaults" {
    const desc = nozzle.ReceiverDesc{
        .name = "test",
        .application_name = "test",
    };
    try std.testing.expectEqual(nozzle.ReceiveMode.latest_only, desc.receive_mode);
}

test "acquire desc defaults" {
    const desc = nozzle.AcquireDesc{};
    try std.testing.expectEqual(@as(u64, 0), desc.timeout_ms);
}

test "mapped pixels row bounds checking" {
    var buf: [64]u8 = undefined;
    @memset(&buf, 0xAA);

    const mp = nozzle.MappedPixels{
        .data = &buf,
        .row_stride_bytes = 8,
        .width = 8,
        .height = 4,
        .format = .r8_unorm,
        .origin = .top_left,
    };

    // valid rows
    try std.testing.expect(mp.row(0) != null);
    try std.testing.expect(mp.row(3) != null);

    // out of bounds
    try std.testing.expect(mp.row(4) == null);
    try std.testing.expect(mp.row(255) == null);

    // row content
    const row0 = mp.row(0).?;
    try std.testing.expectEqual(@as(usize, 8), row0.len);

    // row data starts at correct offset
    const row1 = mp.row(1).?;
    try std.testing.expectEqual(@as(usize, 8), row1.len);
    try std.testing.expectEqual(@intFromPtr(&buf[8]), @intFromPtr(row1.ptr));
}

test "mapped pixels totalBytes and asSlice" {
    var buf: [128]u8 = undefined;

    const mp = nozzle.MappedPixels{
        .data = &buf,
        .row_stride_bytes = 16,
        .width = 16,
        .height = 8,
        .format = .r8_unorm,
        .origin = .top_left,
    };

    try std.testing.expectEqual(@as(usize, 128), mp.totalBytes());

    const slice = mp.asSlice();
    try std.testing.expectEqual(@as(usize, 128), slice.len);
}

// ============================================================================
// GPU-dependent tests (require a running GPU backend)
// These tests will be skipped on CI without GPU
// ============================================================================

test "sender create and destroy" {
    const sender = nozzle.Sender.create(.{
        .name = "zig-test-sender",
        .application_name = "zig-test",
        .ring_buffer_size = 3,
    }) catch |err| switch (err) {
        error.UnsupportedBackend, error.ResourceCreationFailed => {
            std.debug.print("skip: no GPU ({})\n", .{err});
            return error.SkipZigTest;
        },
        else => return err,
    };
    defer sender.destroy();

    const info = sender.info() catch unreachable;
    try std.testing.expectEqualStrings("zig-test-sender", info.name);
    try std.testing.expectEqualStrings("zig-test", info.application_name);
    try std.testing.expect(info.backend == .metal or info.backend == .d3d11 or info.backend == .opengl or info.backend == .dma_buf);
}

test "sender create with empty name fails" {
    const result = nozzle.Sender.create(.{
        .name = "",
        .application_name = "test",
    });
    try std.testing.expectError(error.InvalidArgument, result);
}

test "sender create with zero dimensions fails" {
    const sender = nozzle.Sender.create(.{
        .name = "zig-test-dims",
        .application_name = "zig-test",
    }) catch |err| switch (err) {
        error.UnsupportedBackend, error.ResourceCreationFailed => return error.SkipZigTest,
        else => return err,
    };
    defer sender.destroy();

    const result = sender.acquireWritableFrame(0, 0, .rgba8_unorm);
    try std.testing.expectError(error.InvalidArgument, result);
}

test "receiver create and connected info" {
    const receiver = nozzle.Receiver.create(.{
        .name = "zig-test-nonexistent-sender",
        .application_name = "zig-test",
        .receive_mode = .latest_only,
    }) catch |err| switch (err) {
        // receiver may fail if sender doesn't exist yet or no GPU
        error.SenderNotFound,
        error.UnsupportedBackend,
        error.ResourceCreationFailed,
        => return error.SkipZigTest,
        else => return err,
    };
    defer receiver.destroy();

    // Not connected to any sender yet
    try std.testing.expect(!receiver.isConnected());
}

test "enumerate senders returns without error" {
    const count = nozzle.enumerateSenders() catch |err| switch (err) {
        error.Unknown => return error.SkipZigTest,
        else => return err,
    };
    // count should be >= 0 (no senders running in test)
    try std.testing.expect(count >= 0);
}

test "sender acquire writable frame and commit" {
    const sender = nozzle.Sender.create(.{
        .name = "zig-test-frame",
        .application_name = "zig-test",
    }) catch |err| switch (err) {
        error.UnsupportedBackend, error.ResourceCreationFailed => return error.SkipZigTest,
        else => return err,
    };
    defer sender.destroy();

    const frame = sender.acquireWritableFrame(64, 64, .rgba8_unorm) catch |err| switch (err) {
        error.ResourceCreationFailed => return error.SkipZigTest,
        else => return err,
    };

    const frame_info = try frame.info();
    try std.testing.expectEqual(@as(u32, 64), frame_info.width);
    try std.testing.expectEqual(@as(u32, 64), frame_info.height);
    // format may be fallbacked (e.g. rgba8_unorm → bgra8_unorm on macOS/CGL)
    try std.testing.expect(frame_info.format.bytesPerPixel() != null);
    try std.testing.expectEqual(@as(u8, 4), frame_info.format.bytesPerPixel().?);

    // write pixels and verify
    const pixels = try frame.lockWritablePixels(.top_left);
    defer frame.unlockWritablePixels();

    try std.testing.expectEqual(@as(u32, 64), pixels.width);
    try std.testing.expectEqual(@as(u32, 64), pixels.height);
    try std.testing.expectEqual(@as(u64, 64 * 4), pixels.row_stride_bytes);

    // write pattern and verify
    const row0 = pixels.row(0).?;
    @memset(row0, 0xAB);
    try std.testing.expectEqual(@as(u8, 0xAB), row0[0]);
    try std.testing.expectEqual(@as(u8, 0xAB), row0[63 * 4 + 3]);

    try sender.commitFrame(frame);
}
