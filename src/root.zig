const std = @import("std");

pub const c = @cImport({
    @cInclude("nozzle/nozzle_c.h");
});

pub const Error = error{
    Unknown,
    InvalidArgument,
    UnsupportedBackend,
    UnsupportedFormat,
    DeviceMismatch,
    ResourceCreationFailed,
    SharedHandleFailed,
    SenderNotFound,
    SenderClosed,
    Timeout,
    BackendError,
};

pub fn checkCode(code: c.NozzleErrorCode) Error!void {
    switch (code) {
        c.NOZZLE_OK => {},
        c.NOZZLE_ERROR_UNKNOWN => return Error.Unknown,
        c.NOZZLE_ERROR_INVALID_ARGUMENT => return Error.InvalidArgument,
        c.NOZZLE_ERROR_UNSUPPORTED_BACKEND => return Error.UnsupportedBackend,
        c.NOZZLE_ERROR_UNSUPPORTED_FORMAT => return Error.UnsupportedFormat,
        c.NOZZLE_ERROR_DEVICE_MISMATCH => return Error.DeviceMismatch,
        c.NOZZLE_ERROR_RESOURCE_CREATION_FAILED => return Error.ResourceCreationFailed,
        c.NOZZLE_ERROR_SHARED_HANDLE_FAILED => return Error.SharedHandleFailed,
        c.NOZZLE_ERROR_SENDER_NOT_FOUND => return Error.SenderNotFound,
        c.NOZZLE_ERROR_SENDER_CLOSED => return Error.SenderClosed,
        c.NOZZLE_ERROR_TIMEOUT => return Error.Timeout,
        c.NOZZLE_ERROR_BACKEND_ERROR => return Error.BackendError,
        else => return Error.Unknown,
    }
}

pub const BackendType = enum(c.NozzleBackendType) {
    unknown = c.NOZZLE_BACKEND_UNKNOWN,
    d3d11 = c.NOZZLE_BACKEND_D3D11,
    metal = c.NOZZLE_BACKEND_METAL,
    opengl = c.NOZZLE_BACKEND_OPENGL,
    dma_buf = c.NOZZLE_BACKEND_DMA_BUF,
};

pub const TextureFormat = enum(c.NozzleTextureFormat) {
    unknown = c.NOZZLE_FORMAT_UNKNOWN,
    r8_unorm = c.NOZZLE_FORMAT_R8_UNORM,
    rg8_unorm = c.NOZZLE_FORMAT_RG8_UNORM,
    rgba8_unorm = c.NOZZLE_FORMAT_RGBA8_UNORM,
    bgra8_unorm = c.NOZZLE_FORMAT_BGRA8_UNORM,
    rgba8_srgb = c.NOZZLE_FORMAT_RGBA8_SRGB,
    bgra8_srgb = c.NOZZLE_FORMAT_BGRA8_SRGB,
    r16_unorm = c.NOZZLE_FORMAT_R16_UNORM,
    rg16_unorm = c.NOZZLE_FORMAT_RG16_UNORM,
    rgba16_unorm = c.NOZZLE_FORMAT_RGBA16_UNORM,
    r16_float = c.NOZZLE_FORMAT_R16_FLOAT,
    rg16_float = c.NOZZLE_FORMAT_RG16_FLOAT,
    rgba16_float = c.NOZZLE_FORMAT_RGBA16_FLOAT,
    r32_float = c.NOZZLE_FORMAT_R32_FLOAT,
    rg32_float = c.NOZZLE_FORMAT_RG32_FLOAT,
    rgba32_float = c.NOZZLE_FORMAT_RGBA32_FLOAT,
    r32_uint = c.NOZZLE_FORMAT_R32_UINT,
    rgba32_uint = c.NOZZLE_FORMAT_RGBA32_UINT,
    depth32_float = c.NOZZLE_FORMAT_DEPTH32_FLOAT,

    pub fn bytesPerPixel(self: TextureFormat) ?u8 {
        return switch (self) {
            .r8_unorm => 1,
            .rg8_unorm => 2,
            .rgba8_unorm => 4,
            .bgra8_unorm => 4,
            .rgba8_srgb => 4,
            .bgra8_srgb => 4,
            .r16_unorm => 2,
            .rg16_unorm => 4,
            .rgba16_unorm => 8,
            .r16_float => 2,
            .rg16_float => 4,
            .rgba16_float => 8,
            .r32_float => 4,
            .rg32_float => 8,
            .rgba32_float => 16,
            .r32_uint => 4,
            .rgba32_uint => 16,
            .depth32_float => 4,
            .unknown => null,
        };
    }
};

pub const ReceiveMode = enum(c.NozzleReceiveMode) {
    latest_only = c.NOZZLE_RECEIVE_LATEST_ONLY,
    sequential_best_effort = c.NOZZLE_RECEIVE_SEQUENTIAL_BEST_EFFORT,
};

pub const FrameStatus = enum(c.NozzleFrameStatus) {
    new = c.NOZZLE_FRAME_NEW,
    no_new = c.NOZZLE_FRAME_NO_NEW,
    dropped = c.NOZZLE_FRAME_DROPPED,
    sender_closed = c.NOZZLE_FRAME_SENDER_CLOSED,
    err = c.NOZZLE_FRAME_ERROR,
};

pub const TextureOrigin = enum(c.NozzleTextureOrigin) {
    top_left = c.NOZZLE_ORIGIN_TOP_LEFT,
    bottom_left = c.NOZZLE_ORIGIN_BOTTOM_LEFT,
};

pub const FormatSource = enum(c.NozzleFormatSource) {
    unknown = c.NOZZLE_FORMAT_SOURCE_UNKNOWN,
    requested = c.NOZZLE_FORMAT_SOURCE_REQUESTED,
    caller_hint = c.NOZZLE_FORMAT_SOURCE_CALLER_HINT,
    native_observed = c.NOZZLE_FORMAT_SOURCE_NATIVE_OBSERVED,
};

pub const NativeFormatKind = enum(c.NozzleNativeFormatKind) {
    unknown = c.NOZZLE_NATIVE_KIND_UNKNOWN,
    mtl_pixel_format = c.NOZZLE_NATIVE_KIND_MTL_PIXEL_FORMAT,
    dxgi_format = c.NOZZLE_NATIVE_KIND_DXGI_FORMAT,
    drm_fourcc = c.NOZZLE_NATIVE_KIND_DRM_FOURCC,
    gl_internal_format = c.NOZZLE_NATIVE_KIND_GL_INTERNAL_FORMAT,
};

pub const SenderDesc = struct {
    name: [:0]const u8,
    application_name: [:0]const u8,
    ring_buffer_size: u32 = 3,
    allow_format_fallback: bool = true,
    fallback_flags: u32 = 3,
    fallback_flags_valid: bool = true,
};

pub const ReceiverDesc = struct {
    name: [:0]const u8,
    application_name: [:0]const u8,
    receive_mode: ReceiveMode = .latest_only,
};

pub const AcquireDesc = struct {
    timeout_ms: u64 = 0,
};

pub const SenderInfo = struct {
    name: [:0]const u8,
    application_name: [:0]const u8,
    id: [:0]const u8,
    backend: BackendType,
};

pub const ConnectedSenderInfo = struct {
    name: [:0]const u8,
    application_name: [:0]const u8,
    id: [:0]const u8,
    backend: BackendType,
    width: u32,
    height: u32,
    format: TextureFormat,
    semantic_format: TextureFormat,
    estimated_fps: f64,
    frame_counter: u64,
    last_update_time_ns: u64,
};

pub const FrameInfo = struct {
    frame_index: u64,
    timestamp_ns: u64,
    width: u32,
    height: u32,
    format: TextureFormat,
    semantic_format: TextureFormat,
    dropped_frame_count: u32,
};

pub const ResolvedTextureFormat = struct {
    storage_format: TextureFormat,
    semantic_format: TextureFormat,
    format_source: FormatSource,
    native_backend: BackendType,
    native_kind: NativeFormatKind,
    native_value: u32,
    channel_order: u32,
    component_type: u32,
    component_bits: u8,
    channel_count: u8,
    bytes_per_pixel: u8,
};

pub const MappedPixels = struct {
    data: [*]u8,
    row_stride_bytes: u64,
    width: u32,
    height: u32,
    format: TextureFormat,
    origin: TextureOrigin,

    pub fn row(self: MappedPixels, y: u32) ?[]u8 {
        if (y >= self.height) return null;
        const start = @as(usize, y) * @as(usize, self.row_stride_bytes);
        const end = start + @as(usize, self.row_stride_bytes);
        return self.data[start..end];
    }

    pub fn totalBytes(self: MappedPixels) usize {
        return @as(usize, self.height) * @as(usize, self.row_stride_bytes);
    }

    pub fn asSlice(self: MappedPixels) []u8 {
        return self.data[0..self.totalBytes()];
    }
};

pub const TextureWrapDesc = struct {
    native_texture: ?*anyopaque,
    width: u32,
    height: u32,
    format: TextureFormat,
    backend: BackendType,
};

pub const Texture = struct {
    raw: *c.NozzleTexture,

    pub fn wrap(desc: TextureWrapDesc) Error!Texture {
        const c_desc = c.NozzleTextureWrapDesc{
            .native_texture = desc.native_texture,
            .width = desc.width,
            .height = desc.height,
            .format = @intFromEnum(desc.format),
            .backend = @intFromEnum(desc.backend),
        };
        var raw: ?*c.NozzleTexture = null;
        try checkCode(c.nozzle_texture_wrap(&c_desc, &raw));
        return Texture{ .raw = raw.? };
    }

    pub fn destroy(self: Texture) void {
        c.nozzle_texture_destroy(self.raw);
    }
};

pub const Sender = struct {
    raw: *c.NozzleSender,

    pub fn create(desc: SenderDesc) Error!Sender {
        var raw: ?*c.NozzleSender = null;
        const c_desc = c.NozzleSenderDesc{
            .name = desc.name.ptr,
            .application_name = desc.application_name.ptr,
            .ring_buffer_size = desc.ring_buffer_size,
            .fallback_flags = desc.fallback_flags,
            .fallback_flags_valid = if (desc.fallback_flags_valid) 1 else 0,
        };
        try checkCode(c.nozzle_sender_create(&c_desc, &raw));
        return Sender{ .raw = raw.? };
    }

    pub fn destroy(self: Sender) void {
        c.nozzle_sender_destroy(self.raw);
    }

    pub fn acquireWritableFrame(self: Sender, width: u32, height: u32, format: TextureFormat) Error!WritableFrame {
        var raw: ?*c.NozzleFrame = null;
        try checkCode(c.nozzle_sender_acquire_writable_frame(self.raw, width, height, @intFromEnum(format), &raw));
        return WritableFrame{ .raw = raw.? };
    }

    pub fn commitFrame(self: Sender, frame: WritableFrame) Error!void {
        try checkCode(c.nozzle_sender_commit_frame(self.raw, frame.raw));
    }

    pub fn publishTexture(self: Sender, texture: Texture) Error!void {
        try checkCode(c.nozzle_sender_publish_texture(self.raw, texture.raw));
    }

    pub fn publishNativeTexture(self: Sender, native_texture: ?*anyopaque, width: u32, height: u32, format: TextureFormat) Error!void {
        try checkCode(c.nozzle_sender_publish_native_texture(self.raw, native_texture, width, height, @intFromEnum(format)));
    }

    pub fn publishGLTexture(self: Sender, gl_name: u32, gl_target: u32, width: u32, height: u32, format: TextureFormat) Error!void {
        try checkCode(c.nozzle_sender_publish_gl_texture(self.raw, gl_name, gl_target, width, height, @intFromEnum(format)));
    }

    pub fn info(self: Sender) Error!SenderInfo {
        var raw_info: c.NozzleSenderInfo = undefined;
        try checkCode(c.nozzle_sender_get_info(self.raw, &raw_info));
        return SenderInfo{
            .name = std.mem.sliceTo(raw_info.name, 0),
            .application_name = std.mem.sliceTo(raw_info.application_name, 0),
            .id = std.mem.sliceTo(raw_info.id, 0),
            .backend = @enumFromInt(raw_info.backend),
        };
    }
};

pub const Receiver = struct {
    raw: *c.NozzleReceiver,

    pub fn create(desc: ReceiverDesc) Error!Receiver {
        var raw: ?*c.NozzleReceiver = null;
        const c_desc = c.NozzleReceiverDesc{
            .name = desc.name.ptr,
            .application_name = desc.application_name.ptr,
            .receive_mode = @intFromEnum(desc.receive_mode),
        };
        try checkCode(c.nozzle_receiver_create(&c_desc, &raw));
        return Receiver{ .raw = raw.? };
    }

    pub fn destroy(self: Receiver) void {
        c.nozzle_receiver_destroy(self.raw);
    }

    pub fn acquireFrame(self: Receiver, desc: AcquireDesc) Error!Frame {
        var raw: ?*c.NozzleFrame = null;
        const c_desc = c.NozzleAcquireDesc{
            .timeout_ms = desc.timeout_ms,
        };
        try checkCode(c.nozzle_receiver_acquire_frame(self.raw, &c_desc, &raw));
        return Frame{ .raw = raw.? };
    }

    pub fn connectedInfo(self: Receiver) Error!ConnectedSenderInfo {
        var raw_info: c.NozzleConnectedSenderInfo = undefined;
        try checkCode(c.nozzle_receiver_get_connected_info(self.raw, &raw_info));
        return ConnectedSenderInfo{
            .name = std.mem.sliceTo(raw_info.name, 0),
            .application_name = std.mem.sliceTo(raw_info.application_name, 0),
            .id = std.mem.sliceTo(raw_info.id, 0),
            .backend = @enumFromInt(raw_info.backend),
            .width = raw_info.width,
            .height = raw_info.height,
            .format = @enumFromInt(raw_info.format),
            .semantic_format = @enumFromInt(raw_info.semantic_format),
            .estimated_fps = raw_info.estimated_fps,
            .frame_counter = raw_info.frame_counter,
            .last_update_time_ns = raw_info.last_update_time_ns,
        };
    }

    pub fn isConnected(self: Receiver) bool {
        _ = self.connectedInfo() catch return false;
        return true;
    }
};

pub const Frame = struct {
    raw: *c.NozzleFrame,

    pub fn release(self: Frame) void {
        c.nozzle_frame_release(self.raw);
    }

    pub fn info(self: Frame) Error!FrameInfo {
        var raw_info: c.NozzleFrameInfo = undefined;
        try checkCode(c.nozzle_frame_get_info(self.raw, &raw_info));
        return FrameInfo{
            .frame_index = raw_info.frame_index,
            .timestamp_ns = raw_info.timestamp_ns,
            .width = raw_info.width,
            .height = raw_info.height,
            .format = @enumFromInt(raw_info.format),
            .semantic_format = @enumFromInt(raw_info.semantic_format),
            .dropped_frame_count = raw_info.dropped_frame_count,
        };
    }

    pub fn resolvedFormat(self: Frame) Error!ResolvedTextureFormat {
        var raw: c.NozzleResolvedTextureFormat = undefined;
        try checkCode(c.nozzle_frame_get_resolved_format(self.raw, &raw));
        return ResolvedTextureFormat{
            .storage_format = @enumFromInt(raw.storage_format),
            .semantic_format = @enumFromInt(raw.semantic_format),
            .format_source = @enumFromInt(raw.format_source),
            .native_backend = @enumFromInt(raw.native_backend),
            .native_kind = @enumFromInt(raw.native_kind),
            .native_value = raw.native_value,
            .channel_order = raw.channel_order,
            .component_type = raw.component_type,
            .component_bits = raw.component_bits,
            .channel_count = raw.channel_count,
            .bytes_per_pixel = raw.bytes_per_pixel,
        };
    }

    pub fn lockPixels(self: Frame, origin: TextureOrigin) Error!MappedPixels {
        var mapped: c.NozzleMappedPixels = undefined;
        try checkCode(c.nozzle_frame_lock_pixels_with_origin(self.raw, @intFromEnum(origin), &mapped));
        return mappedPixelsFromC(mapped);
    }

    pub fn lockWritablePixels(self: Frame, origin: TextureOrigin) Error!MappedPixels {
        var mapped: c.NozzleMappedPixels = undefined;
        try checkCode(c.nozzle_frame_lock_writable_pixels_with_origin(self.raw, @intFromEnum(origin), &mapped));
        return mappedPixelsFromC(mapped);
    }

    pub fn unlockPixels(self: Frame) void {
        c.nozzle_frame_unlock_pixels(self.raw);
    }

    pub fn unlockWritablePixels(self: Frame) void {
        c.nozzle_frame_unlock_writable_pixels(self.raw);
    }

    pub fn copyToNativeTexture(self: Frame, native_texture: ?*anyopaque, width: u32, height: u32, format: TextureFormat) Error!void {
        try checkCode(c.nozzle_frame_copy_to_native_texture(self.raw, native_texture, width, height, @intFromEnum(format)));
    }

    pub fn copyToGLTexture(self: Frame, gl_name: u32, gl_target: u32, width: u32, height: u32, format: TextureFormat) Error!void {
        try checkCode(c.nozzle_frame_copy_to_gl_texture(self.raw, gl_name, gl_target, width, height, @intFromEnum(format)));
    }
};

pub const WritableFrame = struct {
    raw: *c.NozzleFrame,

    pub fn info(self: WritableFrame) Error!FrameInfo {
        var raw_info: c.NozzleFrameInfo = undefined;
        try checkCode(c.nozzle_frame_get_info(self.raw, &raw_info));
        return FrameInfo{
            .frame_index = raw_info.frame_index,
            .timestamp_ns = raw_info.timestamp_ns,
            .width = raw_info.width,
            .height = raw_info.height,
            .format = @enumFromInt(raw_info.format),
            .semantic_format = @enumFromInt(raw_info.semantic_format),
            .dropped_frame_count = raw_info.dropped_frame_count,
        };
    }

    pub fn lockPixels(self: WritableFrame, origin: TextureOrigin) Error!MappedPixels {
        var mapped: c.NozzleMappedPixels = undefined;
        try checkCode(c.nozzle_frame_lock_pixels_with_origin(self.raw, @intFromEnum(origin), &mapped));
        return mappedPixelsFromC(mapped);
    }

    pub fn lockWritablePixels(self: WritableFrame, origin: TextureOrigin) Error!MappedPixels {
        var mapped: c.NozzleMappedPixels = undefined;
        try checkCode(c.nozzle_frame_lock_writable_pixels_with_origin(self.raw, @intFromEnum(origin), &mapped));
        return mappedPixelsFromC(mapped);
    }

    pub fn unlockPixels(self: WritableFrame) void {
        c.nozzle_frame_unlock_pixels(self.raw);
    }

    pub fn unlockWritablePixels(self: WritableFrame) void {
        c.nozzle_frame_unlock_writable_pixels(self.raw);
    }
};

fn mappedPixelsFromC(mapped: c.NozzleMappedPixels) MappedPixels {
    return .{
        .data = @ptrCast(@alignCast(mapped.data)),
        .row_stride_bytes = @intCast(mapped.row_stride_bytes),
        .width = mapped.width,
        .height = mapped.height,
        .format = @enumFromInt(mapped.format),
        .origin = @enumFromInt(mapped.origin),
    };
}

pub fn enumerateSenders() Error!u32 {
    var array: c.NozzleSenderInfoArray = undefined;
    const rc = c.nozzle_enumerate_senders(&array);
    if (rc != c.NOZZLE_OK) return Error.Unknown;

    const count = array.count;
    c.nozzle_free_sender_info_array(&array);
    return count;
}

pub fn getDefaultDevice() Error!?*c.NozzleDevice {
    var device: ?*c.NozzleDevice = null;
    try checkCode(c.nozzle_device_get_default(&device));
    return device;
}

pub fn destroyDevice(device: *c.NozzleDevice) void {
    c.nozzle_device_destroy(device);
}

pub fn swizzleChannels(src: []const u8, dst: []u8, width: u32, height: u32, src_row_bytes: u32, dst_row_bytes: u32, format: TextureFormat, permute_map: [4]u8) Error!void {
    try checkCode(c.nozzle_swizzle_channels(src.ptr, dst.ptr, width, height, src_row_bytes, dst_row_bytes, @intFromEnum(format), &permute_map));
}

pub fn widenUint16ToUint32(src: []const u8, dst: []u8, width: u32, height: u32, src_row_bytes: u32, dst_row_bytes: u32, channels: u32) Error!void {
    try checkCode(c.nozzle_widen_uint16_to_uint32(src.ptr, dst.ptr, width, height, src_row_bytes, dst_row_bytes, channels));
}

pub fn convertUint32ToFloat32(src: []const u8, dst: []u8, width: u32, height: u32, src_row_bytes: u32, dst_row_bytes: u32, channels: u32) Error!void {
    try checkCode(c.nozzle_convert_uint32_to_float32(src.ptr, dst.ptr, width, height, src_row_bytes, dst_row_bytes, channels));
}
