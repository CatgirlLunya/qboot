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
            .writeStr = terminal.writeString,
        },
        .memory = .{
            .init = memory_map.init,
            .map = &memory_map.memoryMap,
        },
        .init = init,
    };
}
