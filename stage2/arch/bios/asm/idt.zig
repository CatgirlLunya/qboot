const std = @import("std");

const isr = @import("isr.zig");
const frame = @import("frame.zig");
const debug = @import("../debug.zig");

pub const GateType = enum(u4) {
    task_gate = 0x5,
    interrupt_gate_16 = 0x6,
    trap_gate_16 = 0x7,
    interrupt_gate_32 = 0xE,
    trap_gate_32 = 0xF,
};

// Format can be found at https://wiki.osdev.org/IDT
// Flags: PDD0GGGG
// - P is the Present Bit, must be set to 1 for all valid entries
// - D is the Cpu Priviledge Level needed to use INT to use this, 0-3
// - G is the Gate Type
pub const Flags = packed union {
    flags: u8,
    specific: packed struct {
        gate_type: GateType = .trap_gate_32,
        reserved: u1 = 0,
        priviledge_level: u2 = 0,
        present: bool = true,
    },

    comptime {
        std.debug.assert(@sizeOf(@This()) == 1);
    }
};

pub const Entry = packed struct {
    isr_low: u16,
    kernel_cs: u16 = 0x8,
    reserved: u8 = 0,
    flags: Flags = .{ .specific = .{} },
    isr_high: u16,
};

pub const Descriptor = packed struct {
    size: u16,
    pointer: usize,
};

pub const ISRHandler = *const fn (isr.InterruptInfo) callconv(.C) void;

// zig fmt: off
fn getExceptionMessage(vec: usize) []const u8 {
    return switch (vec) {
        0 => "Division By Zero",
        1 => "Debug",
        2 => "Non Maskable Interrupt", 
        3 => "Breakpoint", 
        4 => "Into Detected Overflow", 
        5 => "Out of Bounds", 
        6 => "Invalid Opcode", 
        7 => "No Coprocessor", 
        8 => "Double Fault", 
        9 => "Coprocessor Segment Overrun", 
        10 => "Bad TSS", 
        11 => "Segment Not Present", 
        12 => "Stack Fault", 
        13 => "General Protection Fault", 
        14 => "Page Fault", 
        15 => "Unknown Interrupt", 
        16 => "Coprocessor Fault", 
        17 => "Alignment Check", 
        18 => "Machine Check", 
        19...31 => "Reserved",
        else => "Unknown"
    };
}
// zig fmt: on

// Aligning gives performance https://wiki.osdev.org/Interrupts_Tutorial
var table: [256]Entry align(0x10) = undefined;

// Stores the functions that are run on an interrupt
pub var func_table: [256]ISRHandler = undefined;

pub fn makeEntry(func: isr.Stub) Entry {
    const int_addr = @intFromPtr(func);

    const entry: Entry = .{
        .isr_low = @truncate(int_addr),
        .isr_high = @truncate(int_addr >> 16),
    };

    return entry;
}

pub fn defaultISRHandler(regs: isr.InterruptInfo) callconv(.C) void {
    std.log.info("ISR Info Dump:", .{});
    regs.dump();
    std.log.info("Frame Dump:", .{});
    const f = frame.getFrame();
    f.dump();
    @panic(getExceptionMessage(regs.interrupt_number));
}

pub fn installInterrupt(comptime vec: u8, func: ISRHandler) void {
    func_table[vec] = func;
    table[vec] = makeEntry(isr.makeStub(vec));
}

pub fn init() void {
    inline for (0..32) |vec| {
        installInterrupt(vec, defaultISRHandler);
    }

    const descriptor = Descriptor{
        .pointer = @intFromPtr(&table),
        .size = @sizeOf(Entry) * 256,
    };

    const idtr = @intFromPtr(&descriptor);

    asm volatile ("lidt (%[idtr])"
        :
        : [idtr] "r" (idtr),
    );
}
