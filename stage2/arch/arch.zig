const builtin = @import("builtin");

pub usingnamespace switch (builtin.os.tag) {
    .uefi => @import("uefi/index.zig"),
    .freestanding => switch (builtin.cpu.arch) {
        .x86 => @import("bios/index.zig"),
        else => @compileError("Unimplemented"),
    },
    else => @compileError("Unimplemented"),
};
