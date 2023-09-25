const api_int = @import("api");
const io = @import("io/io.zig");
const clock = @import("clock.zig");
const memory_map = @import("mm/memory_map.zig");
const pmm = @import("mm/pmm.zig");
const keyboard = @import("keyboard.zig");
const init = @import("init.zig").init;
const disk = @import("disk/disk.zig");

pub fn api() api_int.API {
    return .{
        .clock = .{
            .getTime = clock.getTime,
        },
        .terminals = &.{
            io.terminal_interface,
            io.serial_interface,
        },
        .memory = .{
            .init = memory_map.init,
            .map = &memory_map.memoryMap,
        },
        .allocator = .{
            .init = pmm.init,
            .deinit = pmm.deinit,
            .allocator = pmm.allocator,
        },
        .keyboard = .{
            .init = keyboard.init,
            .getInput = keyboard.getInput,
            .deinit = keyboard.deinit,
        },
        .disk = .{
            .init = disk.init,
            .loadFile = disk.loadFile,
            .deinit = disk.deinit,
        },
        .init = init,
    };
}
