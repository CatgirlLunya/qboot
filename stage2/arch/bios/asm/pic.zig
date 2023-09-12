const cpu = @import("cpu.zig");
const idt = @import("idt.zig");

pub const PIC1_OFFSET = 0xF0;
pub const PIC2_OFFSET = 0xF8;

const PIC1_COMMAND = 0x20;
const PIC1_DATA = 0x21;
const PIC2_COMMAND = 0xA0;
const PIC2_DATA = 0xA1;

const PIC_EOI = 0x20;

// ICW1 bit set, ICW4 is needed, set the IRQ offset, say slave is tied to IRQ2, and use 8086 mode
const PIC1_ICW: [4]u8 = [4]u8{ 0b10001, PIC1_OFFSET, 0b100, 1 };
// Same as above but tell slave it is tied to IRQ 2
const PIC2_ICW: [4]u8 = [4]u8{ 0b10001, PIC2_OFFSET, 2, 1 };

pub fn init() !void {
    cpu.outb(PIC1_COMMAND, PIC1_ICW[0]);
    cpu.inaccurateWait();
    cpu.outb(PIC2_COMMAND, PIC2_ICW[0]);
    cpu.inaccurateWait();

    cpu.outb(PIC1_DATA, PIC1_ICW[1]);
    cpu.inaccurateWait();
    cpu.outb(PIC2_DATA, PIC2_ICW[1]);
    cpu.inaccurateWait();

    cpu.outb(PIC1_DATA, PIC1_ICW[2]);
    cpu.inaccurateWait();
    cpu.outb(PIC2_DATA, PIC2_ICW[2]);
    cpu.inaccurateWait();

    cpu.outb(PIC1_DATA, PIC1_ICW[3]);
    cpu.inaccurateWait();
    cpu.outb(PIC2_DATA, PIC2_ICW[3]);
    cpu.inaccurateWait();

    cpu.outb(PIC1_DATA, 0);
    cpu.outb(PIC2_DATA, 0);

    for (0..16) |line| {
        mask(@intCast(line), true);
    }
    mask(2, false);
}

pub fn installIRQ(comptime line: u8, func: idt.ISRHandler) void {
    idt.installInterrupt(PIC1_OFFSET + line, func);
    mask(line, false);
}

pub fn uninstallIRQ(comptime line: u8) void {
    mask(line, true);
}

pub fn mask(line: u8, set: bool) void {
    var port: u16 = PIC1_DATA;
    var irq = line;
    if (line >= 8) {
        port = PIC2_DATA;
        irq -= 8;
    }
    var value: u8 = 0;
    if (set) {
        value = cpu.inb(port) | (@as(u8, 1) << @as(u3, @intCast(irq)));
    } else {
        value = cpu.inb(port) & ~(@as(u8, 1) << @as(u3, @intCast(irq)));
    }
    cpu.outb(port, value);
}

pub fn eoi(irq: u8) void {
    if (irq >= 8) {
        cpu.outb(PIC2_COMMAND, PIC_EOI);
    }
    cpu.outb(PIC1_COMMAND, PIC_EOI);
}

pub fn deinit() void {
    cpu.outb(PIC2_DATA, 0xFF);
    cpu.outb(PIC1_DATA, 0xFF);
}
