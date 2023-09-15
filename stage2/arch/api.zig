const builtin = @import("builtin");
pub const API = @import("../api/api.zig").API;

pub const api: API = switch (builtin.os.tag) {
    .uefi => @import("uefi/api.zig").api(),
    .freestanding => switch (builtin.cpu.arch) {
        .x86 => @import("bios/api.zig").api(),
        else => @compileError("Unimplemented CPU!"),
    },
    else => @compileError("Unimplemented OS!"),
};
