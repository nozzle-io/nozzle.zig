# nozzle.zig

> This codebase is currently in its AI-slob prototyping phase: the code runs on momentum, vibes, and plausible intent.
> Proper debugging will be introduced once demand graduates from hypothetical to measurable.

Zig bindings for [nozzle](https://github.com/nozzle-io/nozzle) — cross-platform GPU texture sharing between local processes.

## Disclaimer / Notice

This library is currently a work in progress and contains many incomplete features and unverified implementations.
Although it may appear usable at first glance, it may not function correctly.

## Build Requirements

- Zig 0.13+
- C++17 compiler (clang / MSVC)
- macOS 12+, Windows 10+, or Linux

The nozzle C library is built from source via a git submodule. No CMake required — `build.zig` compiles everything directly.

## Build

```bash
zig build
```

### Run Tests

```bash
zig build test
```

### Run Examples

```bash
zig build run-nozzle-sender
zig build run-nozzle-receiver
```

## Usage

### Sender

```zig
const nozzle = @import("nozzle");

const sender = try nozzle.Sender.create(.{
    .name = "zig-sender",
    .application_name = "MyApp",
    .ring_buffer_size = 3,
});
defer sender.destroy();

const frame = try sender.acquireWritableFrame(1920, 1080, .rgba8_unorm);
{
    const pixels = try frame.lockWritablePixels(.top_left);
    defer frame.unlockWritablePixels();

    var y: u32 = 0;
    while (y < pixels.height) : (y += 1) {
        if (pixels.row(y)) |row_slice| {
            @memset(row_slice, 0xFF);
        }
    }
}
try sender.commitFrame(frame);
```

### Receiver

```zig
const nozzle = @import("nozzle");

const receiver = try nozzle.Receiver.create(.{
    .name = "zig-sender",
    .application_name = "MyViewer",
});
defer receiver.destroy();

const frame = try receiver.acquireFrame(.{ .timeout_ms = 5000 });
defer frame.release();

const info = try frame.info();
std.debug.print("{}x{} frame #{}\n", .{
    info.width,
    info.height,
    info.frame_index,
});
```

### Discovery

```zig
const nozzle = @import("nozzle");

const count = try nozzle.enumerateSenders();
std.debug.print("found {} senders\n", .{count});
```

## Error Handling

All fallible operations return Zig error unions. C error codes map directly to Zig errors:

```zig
const frame = nozzle.Sender.acquireWritableFrame(0, 0, .unknown) catch |err| {
    switch (err) {
        error.InvalidArgument => { /* ... */ },
        error.UnsupportedFormat => { /* ... */ },
        else => { /* ... */ },
    }
};
```

## Texture Formats

| Format | Bytes/Pixel |
|--------|-------------|
| `r8_unorm` | 1 |
| `rg8_unorm` | 2 |
| `rgba8_unorm` / `bgra8_unorm` | 4 |
| `rgba8_srgb` / `bgra8_srgb` | 4 |
| `r16_unorm` | 2 |
| `rg16_unorm` | 4 |
| `rgba16_unorm` | 8 |
| `r16_float` | 2 |
| `rg16_float` | 4 |
| `rgba16_float` | 8 |
| `r32_float` | 4 |
| `rg32_float` | 8 |
| `rgba32_float` | 16 |
| `r32_uint` | 4 |
| `rgba32_uint` | 16 |
| `depth32_float` | 4 |

## Platform Notes

- **macOS**: Links Metal, IOSurface, Foundation, Accelerate, OpenGL frameworks automatically
- **Windows**: Links d3d11, dxgi, opengl32, bcrypt automatically
- **Linux**: Links drm, gbm, EGL, GL automatically

## License

MIT
