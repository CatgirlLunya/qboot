const cpu = @import("../asm/cpu.zig");
const terminal = @import("api").terminal;

const COM1_PORT = 0x3F8;

const LineControlRegister = packed struct(u8) {
    word_length: enum(u2) { five, six, seven, eight } = .eight,
    stop_bit_length: bool = false, // 1 stop bit, 2 stop bits
    parity: enum(u3) {
        none = 0b000,
        odd = 0b001,
        even = 0b011,
        high = 0b101,
        low = 0b111,
    } = .none,
    break_enable: bool = false,
    dlab: bool = false,
};

fn setLineControlRegister(port: u16, lcr: LineControlRegister) void {
    cpu.outb(port + 3, @bitCast(lcr));
}

fn setBaudDivisor(port: u16, divisor: u16) void {
    setLineControlRegister(port, .{ .dlab = true });
    cpu.outb(port, @intCast(divisor & 0xFF));
    cpu.outb(port + 1, @intCast(divisor << 8));
    setLineControlRegister(port, .{ .dlab = false });
}

const InterruptRegister = packed struct(u8) {
    data_available_interrupt: bool = false,
    transmitter_holding_register_empty_interrupt: bool = false,
    received_line_status_interrupt: bool = false,
    enable_modem_status_interrupt: bool = false,
    enable_sleep_mode: bool = false,
    enable_low_power_mode: bool = false,
    reserved: u2 = 0,
};

fn setInterruptRegister(port: u16, reg: InterruptRegister) void {
    cpu.outb(port + 1, @bitCast(reg));
}

const ModemControlRegister = packed struct(u8) {
    data_terminal_ready: bool = false,
    request_to_send: bool = false,
    out_1: bool = false, // (unused)
    out_2: bool = false, // (IRQ)
    loop: bool = false, // Loopback device
    unused: u3 = 0,
};

fn setModemControlRegister(port: u16, reg: ModemControlRegister) void {
    cpu.outb(port + 4, @bitCast(reg));
}

fn testPort(port: u16) bool {
    cpu.outb(port, 0xAE);
    return cpu.inb(port) == 0xAE;
}

const errors = error{
    FailedSelfTest,
};

fn receive(port: u16) void {
    while (cpu.inb(port + 5) & 1 == 0) {} // Polls line status register for data ready bit
    return cpu.inb(port);
}

fn send(port: u16, byte: u8) void {
    while (cpu.inb(port + 5) & 0x20 == 0) {} // Polls line status register for transmit empty bit
    cpu.outb(port, byte);
}

fn sendStr(port: u16, str: []const u8) void {
    for (str) |c| {
        send(port, c);
    }
}

pub fn init() !void {
    setInterruptRegister(COM1_PORT, .{});
    setBaudDivisor(COM1_PORT, 3);
    setLineControlRegister(COM1_PORT, .{ .word_length = .eight });
    setModemControlRegister(COM1_PORT, .{ .loop = true });
    setModemControlRegister(COM1_PORT, .{ .loop = false });
    // if (!testPort(COM1_PORT)) return errors.FailedSelfTest;
}

pub fn printChar(byte: u8) !void {
    send(COM1_PORT, byte);
    if (byte == '\n') send(COM1_PORT, '\r');
}

pub fn setColor(fg: terminal.fg_color, bg: terminal.bg_color) !void {
    const esc = [1]u8{27};
    switch (fg) {
        .black => sendStr(COM1_PORT, esc ++ "[30m"),
        .red => sendStr(COM1_PORT, esc ++ "[31m"),
        .green => sendStr(COM1_PORT, esc ++ "[32m"),
        .brown => sendStr(COM1_PORT, esc ++ "[33m"),
        .blue => sendStr(COM1_PORT, esc ++ "[34m"),
        .magenta => sendStr(COM1_PORT, esc ++ "[35m"),
        .cyan => sendStr(COM1_PORT, esc ++ "[36m"),
        .gray => sendStr(COM1_PORT, esc ++ "[37m"),
        .dark_gray => sendStr(COM1_PORT, esc ++ "[1;30m"),
        .light_red => sendStr(COM1_PORT, esc ++ "[1;31m"),
        .light_green => sendStr(COM1_PORT, esc ++ "[1;32m"),
        .yellow => sendStr(COM1_PORT, esc ++ "[1;33m"),
        .light_blue => sendStr(COM1_PORT, esc ++ "[1;34m"),
        .light_magenta => sendStr(COM1_PORT, esc ++ "[1;35m"),
        .light_cyan => sendStr(COM1_PORT, esc ++ "[1;36m"),
        .white => sendStr(COM1_PORT, esc ++ "[1;37m"),
    }
    switch (bg) {
        .black => sendStr(COM1_PORT, esc ++ "[40m"),
        .red => sendStr(COM1_PORT, esc ++ "[41m"),
        .green => sendStr(COM1_PORT, esc ++ "[42m"),
        .brown => sendStr(COM1_PORT, esc ++ "[43m"),
        .blue => sendStr(COM1_PORT, esc ++ "[44m"),
        .magenta => sendStr(COM1_PORT, esc ++ "[45m"),
        .cyan => sendStr(COM1_PORT, esc ++ "[46m"),
        .gray => sendStr(COM1_PORT, esc ++ "[47m"),
    }
}
