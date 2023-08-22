pub const idt = @import("asm/idt.zig");

// Initialize things that are only on that platform, IDT isn't needed on UEFI
pub fn init() void {
    idt.init();
}
