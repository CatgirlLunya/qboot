const idt = @import("../idt.zig");
const std = @import("std");

pub const InterruptInfo = extern struct {
    error_code: u32,
    interrupt_number: u32,
    eip: u32,
    cs: u32,
    eflags: u32,

    pub fn dump(self: *const InterruptInfo) void {
        std.log.info("EIP: {}, CS: {}, EFLAGS: {}\nINUM: {}, ERR: {}", .{ self.eip, self.cs, self.eflags, self.interrupt_number, self.error_code });
    }
};

pub const Stub = *const fn () callconv(.Naked) void;

pub fn makeStub(comptime vector: u8) Stub {
    return struct {
        fn stub() callconv(.Naked) void {
            const has_error_code = switch (vector) {
                0x08 => true,
                0x0A...0x0E => true,
                0x11 => true,
                0x15 => true,
                0x1D...0x1E => true,
                else => false,
            };

            if (!comptime (has_error_code)) {
                asm volatile ("push $0"); // Push error code 0 if the function doesn't have one, for consistency
            }

            asm volatile ("push %[vector]"
                :
                : [vector] "i" (vector),
            );

            asm volatile (
                \\lea %[handler], %ebx
                \\mov %esp, %edi
                \\call *(%ebx)
                // Used to adjust from error code and isr vector
                \\add $8, %esp
                \\sti
                \\iret
                :
                : [handler] "m" (&idt.isrHandler),
            );
        }
    }.stub;
}

pub fn init() void {
    inline for (0..32) |c| {
        const f = makeStub(c);
        idt.insertEntry(idt.makeEntry(f), c);
    }
}
