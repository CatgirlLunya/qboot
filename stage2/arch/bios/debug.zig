const cpu = @import("asm/cpu.zig");

pub fn bochsBreak() void {
    cpu.outw(0x8A00, 0x8A00);
    cpu.outw(0x8A00, 0x08AE0);
}
