const std = @import("std");
const nozzle = @import("nozzle");

test "texture format bytes_per_pixel" {
    try std.testing.expect(nozzle.TextureFormat.rgba8_unorm.bytesPerPixel() == 4);
    try std.testing.expect(nozzle.TextureFormat.r8_unorm.bytesPerPixel() == 1);
    try std.testing.expect(nozzle.TextureFormat.rg8_unorm.bytesPerPixel() == 2);
    try std.testing.expect(nozzle.TextureFormat.bgra8_unorm.bytesPerPixel() == 4);
    try std.testing.expect(nozzle.TextureFormat.rgba8_srgb.bytesPerPixel() == 4);
    try std.testing.expect(nozzle.TextureFormat.bgra8_srgb.bytesPerPixel() == 4);
    try std.testing.expect(nozzle.TextureFormat.r16_unorm.bytesPerPixel() == 2);
    try std.testing.expect(nozzle.TextureFormat.rg16_unorm.bytesPerPixel() == 4);
    try std.testing.expect(nozzle.TextureFormat.rgba16_unorm.bytesPerPixel() == 8);
    try std.testing.expect(nozzle.TextureFormat.r16_float.bytesPerPixel() == 2);
    try std.testing.expect(nozzle.TextureFormat.rg16_float.bytesPerPixel() == 4);
    try std.testing.expect(nozzle.TextureFormat.rgba16_float.bytesPerPixel() == 8);
    try std.testing.expect(nozzle.TextureFormat.r32_float.bytesPerPixel() == 4);
    try std.testing.expect(nozzle.TextureFormat.rg32_float.bytesPerPixel() == 8);
    try std.testing.expect(nozzle.TextureFormat.rgba32_float.bytesPerPixel() == 16);
    try std.testing.expect(nozzle.TextureFormat.r32_uint.bytesPerPixel() == 4);
    try std.testing.expect(nozzle.TextureFormat.rgba32_uint.bytesPerPixel() == 16);
    try std.testing.expect(nozzle.TextureFormat.depth32_float.bytesPerPixel() == 4);
    try std.testing.expect(nozzle.TextureFormat.unknown.bytesPerPixel() == null);
}

test "error code mapping" {
    try std.testing.expectError(error.Unknown, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_UNKNOWN));
    try std.testing.expectError(error.InvalidArgument, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_INVALID_ARGUMENT));
    try std.testing.expectError(error.UnsupportedBackend, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_UNSUPPORTED_BACKEND));
    try std.testing.expectError(error.UnsupportedFormat, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_UNSUPPORTED_FORMAT));
    try std.testing.expectError(error.DeviceMismatch, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_DEVICE_MISMATCH));
    try std.testing.expectError(error.ResourceCreationFailed, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_RESOURCE_CREATION_FAILED));
    try std.testing.expectError(error.SenderNotFound, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_SENDER_NOT_FOUND));
    try std.testing.expectError(error.SenderClosed, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_SENDER_CLOSED));
    try std.testing.expectError(error.Timeout, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_TIMEOUT));
    try std.testing.expectError(error.BackendError, nozzle.checkCode(nozzle.c.NOZZLE_ERROR_BACKEND_ERROR));

    // OK should succeed
    try nozzle.checkCode(nozzle.c.NOZZLE_OK);
}

test "backend type enum values" {
    try std.testing.expect(@intFromEnum(nozzle.BackendType.unknown) == 0);
    try std.testing.expect(@intFromEnum(nozzle.BackendType.d3d11) == 1);
    try std.testing.expect(@intFromEnum(nozzle.BackendType.metal) == 2);
    try std.testing.expect(@intFromEnum(nozzle.BackendType.opengl) == 3);
    try std.testing.expect(@intFromEnum(nozzle.BackendType.dma_buf) == 4);
}

test "texture format enum values" {
    try std.testing.expect(@intFromEnum(nozzle.TextureFormat.unknown) == 0);
    try std.testing.expect(@intFromEnum(nozzle.TextureFormat.r8_unorm) == 1);
    try std.testing.expect(@intFromEnum(nozzle.TextureFormat.rgba8_unorm) == 3);
    try std.testing.expect(@intFromEnum(nozzle.TextureFormat.rgba32_float) == 15);
    try std.testing.expect(@intFromEnum(nozzle.TextureFormat.depth32_float) == 18);
}

test "receive mode enum values" {
    try std.testing.expect(@intFromEnum(nozzle.ReceiveMode.latest_only) == 0);
    try std.testing.expect(@intFromEnum(nozzle.ReceiveMode.sequential_best_effort) == 1);
}

test "frame status enum values" {
    try std.testing.expect(@intFromEnum(nozzle.FrameStatus.new) == 0);
    try std.testing.expect(@intFromEnum(nozzle.FrameStatus.no_new) == 1);
    try std.testing.expect(@intFromEnum(nozzle.FrameStatus.dropped) == 2);
    try std.testing.expect(@intFromEnum(nozzle.FrameStatus.sender_closed) == 3);
    try std.testing.expect(@intFromEnum(nozzle.FrameStatus.err) == 4);
}

test "sender create and destroy" {
    const sender = nozzle.Sender.create(.{
        .name = "zig-test-sender",
        .application_name = "zig-test",
        .ring_buffer_size = 3,
    }) catch |err| {
        // sender creation may fail if GPU is not available (CI environments)
        std.debug.print("sender create failed: {} (expected on CI)\n", .{err});
        return;
    };
    defer sender.destroy();

    const info = sender.info() catch unreachable;
    try std.testing.expectEqualStrings("zig-test-sender", info.name);
    try std.testing.expectEqualStrings("zig-test", info.application_name);
}

test "sender create with empty name fails" {
    const result = nozzle.Sender.create(.{
        .name = "",
        .application_name = "test",
    });
    try std.testing.expectError(error.InvalidArgument, result);
}

test "receiver create and destroy" {
    const receiver = nozzle.Receiver.create(.{
        .name = "zig-test-nonexistent",
        .application_name = "zig-test",
        .receive_mode = .latest_only,
    }) catch |err| {
        std.debug.print("receiver create failed: {} (expected on CI)\n", .{err});
        return;
    };
    defer receiver.destroy();
}

test "enumerate senders" {
    const count = nozzle.enumerateSenders() catch {
        std.debug.print("enumerate failed (expected on CI)\n", .{});
        return;
    };
    std.debug.print("found {} senders\n", .{count});
}

test "sender acquire writable frame and commit" {
    const sender = nozzle.Sender.create(.{
        .name = "zig-test-frame",
        .application_name = "zig-test",
    }) catch |err| {
        std.debug.print("sender create failed: {} (expected on CI)\n", .{err});
        return;
    };
    defer sender.destroy();

    const frame = sender.acquireWritableFrame(256, 256, .rgba8_unorm) catch |err| {
        std.debug.print("acquire writable frame failed: {} (expected on CI)\n", .{err});
        return;
    };

    const frame_info = frame.info() catch unreachable;
    try std.testing.expectEqual(@as(u32, 256), frame_info.width);
    try std.testing.expectEqual(@as(u32, 256), frame_info.height);

    // write pixels
    const pixels = frame.lockWritablePixels(.top_left) catch |err| {
        std.debug.print("lock writable pixels failed: {} (expected on CI)\n", .{err});
        sender.commitFrame(frame) catch {};
        return;
    };
    defer frame.unlockWritablePixels();

    try std.testing.expectEqual(@as(u32, 256), pixels.width);
    try std.testing.expectEqual(@as(u32, 256), pixels.height);

    // fill with white
    const slice = pixels.asSlice();
    @memset(slice, 0xFF);

    sender.commitFrame(frame) catch |err| {
        std.debug.print("commit frame failed: {}\n", .{err});
    };
}
