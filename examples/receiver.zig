const std = @import("std");
const nozzle = @import("nozzle");

pub fn main() !void {
    const receiver = try nozzle.Receiver.create(.{
        .name = "zig-sender",
        .application_name = "nozzle-zig-example",
    });
    defer receiver.destroy();

    std.debug.print("waiting for sender...\n", .{});

    const frame = try receiver.acquireFrame(.{ .timeout_ms = 5000 });
    defer frame.release();

    const frame_info = try frame.info();
    std.debug.print("received frame: {}x{} #{d} ({})\n", .{
        frame_info.width,
        frame_info.height,
        frame_info.frame_index,
        frame_info.format,
    });
}
