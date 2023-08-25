const uefi = @import("std").os.uefi;
const debugger_support_protocol = @import("wrapper/debugger_support_protocol.zig");
const std = @import("std");

fn standard_exception(exception_type: isize, context: debugger_support_protocol.SystemContext) callconv(uefi.cc) void {
    _ = context;
    std.log.err("Exception received: {}", .{exception_type});
    @panic("Exception");
    // std.log.err("EAX: {}, EBX: {}, ECX: {}, EDX: {}", .{ context.x64.rax, context.x64.rbx, context.x64.rcx, context.x64.rdx });
    // while (true) {
    //         asm volatile ("hlt");
    // }
}

pub fn init() !void {
    const protocols = try debugger_support_protocol.open();
    std.log.info("Protocols available: {}", .{protocols.len});
    for (0..protocols.len) |pair| {
        const protocol: debugger_support_protocol.DebuggerSupportProtocol = protocols[pair].protocol;
        var max_processor_index: usize = 0;
        try protocol.getMaximumProcessorIndex(&max_processor_index).err();
        std.log.info("Max Processor Index: {}", .{max_processor_index});
        std.log.info("ISA: {}", .{@intFromEnum(protocol.isa)});
        for (0..max_processor_index + 1) |processor| {
            for (0..10) |vec| {
                try protocol.registerExceptionCallback(processor, null, @intCast(vec)).err();
                try protocol.registerExceptionCallback(processor, standard_exception, @intCast(vec)).err();
            }
        }
    }
    try debugger_support_protocol.close(protocols);
}
