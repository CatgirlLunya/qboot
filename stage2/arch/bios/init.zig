pub const idt = @import("asm/idt.zig");
pub const ps2 = @import("ps2/8042.zig");
pub const pic = @import("asm/pic.zig");

// Initialize things that are only on that platform, IDT isn't needed on UEFI
pub fn init() !void {
    asm volatile ("cli");
    idt.init();
    try pic.init();
    try ps2.init();
    asm volatile ("sti");
}
