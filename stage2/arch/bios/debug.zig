const cpu = @import("asm/cpu.zig");

pub fn breakpoint() void {
    asm volatile ("xchgw %bx, %bx");
}
