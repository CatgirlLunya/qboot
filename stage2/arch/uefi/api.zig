const API = @import("../api.zig").API;
const terminal = @import("terminal.zig");
const clock = @import("clock.zig");
const memory_map = @import("mm/memory_map.zig");
const init = @import("init.zig").init;

pub fn api() API {
    return .{
        .clock = .{
            .getTime = clock.getTime,
        },
        .terminal = .{
            .init = terminal.init,
            .setColor = terminal.setColor,
            .writeChar = terminal.writeChar,
        },
        .memory = .{
            .init = memory_map.init,
            .map = &memory_map.memoryMap,
        },
        .allocator = .{
            .init = null,
            .stop = null,
            .allocator = @import("std").os.uefi.pool_allocator,
        },
        .keyboard = null, // Remove later when getInput is done
        //.keyboard = .{
        //    .init = null,
        //    .getInput = undefined,
        //    .deinit = null,
        //},
        .init = init,
    };
}
