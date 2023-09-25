const API = @import("api").API;
const terminal = @import("terminal.zig");
const clock = @import("clock.zig");
const memory_map = @import("mm/memory_map.zig");
const keyboard = @import("keyboard.zig");
const init = @import("init.zig").init;
const disk = @import("disk.zig");

pub fn api() API {
    return .{
        .clock = .{
            .getTime = clock.getTime,
        },
        .terminals = &.{.{
            .init = terminal.init,
            .setColor = terminal.setColor,
            .printChar = terminal.writeChar,
        }},
        .disk = .{
            .init = null,
            .loadFile = disk.loadFile,
            .deinit = null,
        },
        .memory = .{
            .init = memory_map.init,
            .map = &memory_map.memoryMap,
        },
        .allocator = .{
            .init = null,
            .deinit = null,
            .allocator = @import("std").os.uefi.pool_allocator,
        },
        .keyboard = .{
            .init = keyboard.init,
            .getInput = keyboard.getInput,
            .deinit = null,
        },
        .init = init,
    };
}
