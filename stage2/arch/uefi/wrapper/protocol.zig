pub const uefi = @import("std").os.uefi;

pub fn loadProtocol(comptime T: type) !*T {
    const bs = uefi.system_table.boot_services.?;
    var protocol: *T = undefined;
    try bs.locateProtocol(&T.guid, null, @ptrCast(&protocol)).err();
    return protocol;
}

pub fn protocolHandlePair(comptime T: type) type {
    return struct {
        protocol: T,
        handle: uefi.Handle,
    };
}

pub fn openProtocols(comptime T: type) ![]protocolHandlePair(T) {
    const bs = uefi.system_table.boot_services.?;
    var num_handles: usize = 0;
    var handle_buffer: [*]uefi.Handle = undefined;
    try bs.locateHandleBuffer(
        .ByProtocol,
        &T.guid,
        null,
        &num_handles,
        &handle_buffer,
    ).err();

    var protocols: []protocolHandlePair(T) = try uefi.pool_allocator.alloc(protocolHandlePair(T), num_handles);

    for (0..num_handles) |handle_num| {
        var protocol: ?*T = null;
        try bs.openProtocol(
            handle_buffer[handle_num],
            &T.guid,
            @as(*?*anyopaque, @ptrCast(&protocol)),
            uefi.handle,
            null,
            .{ .by_handle_protocol = true },
        ).err();
        if (protocol) |p| {
            protocols[handle_num].protocol = p.*;
            protocols[handle_num].handle = handle_buffer[handle_num];
        }
    }

    return protocols;
}

pub fn closeProtocols(comptime T: type, protocols: []protocolHandlePair(T)) !void {
    const bs = uefi.system_table.boot_services.?;
    for (0..protocols.len) |protocol| {
        try bs.closeProtocol(
            protocols.ptr[protocol].handle,
            &T.guid,
            uefi.handle,
            null,
        ).err();
    }
    uefi.pool_allocator.free(protocols);
}
