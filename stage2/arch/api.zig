const builtin = @import("builtin");
const API = @import("api").API;

pub const writer = @import("writer.zig");
pub const debug = @import("bios/debug.zig");

pub const api: API = switch (builtin.os.tag) {
    .uefi => @import("uefi/api.zig").api(),
    .freestanding => switch (builtin.cpu.arch) {
        .x86 => @import("bios/api.zig").api(),
        else => @compileError("Unimplemented CPU!"),
    },
    else => @compileError("Unimplemented OS!"),
};
