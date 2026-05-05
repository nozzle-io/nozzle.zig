const std = @import("std");
const nozzle = @import("nozzle");

pub fn main() !void {
    const sender = try nozzle.Sender.create(.{
        .name = "zig-sender",
        .application_name = "nozzle-zig-example",
        .ring_buffer_size = 3,
    });
    defer sender.destroy();

    const info = try sender.info();
    std.debug.print("sender: {s} (id: {s}, backend: {})\n", .{
        info.name,
        info.id,
        info.backend,
    });

    const frame = try sender.acquireWritableFrame(256, 256, .rgba8_unorm);
    {
        const pixels = try frame.lockWritablePixels(.top_left);
        defer frame.unlockWritablePixels();

        var y: u32 = 0;
        while (y < pixels.height) : (y += 1) {
            if (pixels.row(y)) |row_slice| {
                for (row_slice) |*b| {
                    b.* = 0xFF;
                }
            }
        }
    }
    try sender.commitFrame(frame);

    std.debug.print("frame committed\n", .{});
}
