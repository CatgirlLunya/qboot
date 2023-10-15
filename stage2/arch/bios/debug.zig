const cpu = @import("asm/cpu.zig");
const frame = @import("asm/frame.zig");

pub fn breakpoint() void {
    asm volatile ("xchgw %bx, %bx");
}

pub fn dumpInfo() void {
    breakpoint();
    frame.getFrame().dump();
}
