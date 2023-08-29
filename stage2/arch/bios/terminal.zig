const cpu = @import("asm/cpu.zig");
const api_terminal = @import("../../api/api.zig").terminal;
const std = @import("std");

const buffer: *volatile [25][160]u8 = @ptrFromInt(0xB8000);

pub fn makeColorInt(fg: api_terminal.fg_color, bg: api_terminal.bg_color) u8 {
    return @intFromEnum(fg) | @intFromEnum(bg) << 4;
}

const Context = struct {
    column: u8 = 0,
    row: u8 = 0,
    cursor_column: u8 = 0,
    cursor_row: u8 = 0,
    color: u8 = makeColorInt(.white, .black),
};

var context: Context = .{};

pub fn init() !void {
    for (0..24) |y| {
        for (0..80) |x| {
            putCharAt(@intCast(x), @intCast(y), 0);
        }
    }
    setCursor(true);
}

pub fn setColor(fg: api_terminal.fg_color, bg: api_terminal.bg_color) !void {
    context.color = makeColorInt(fg, bg);
}

pub fn newLine() void {
    context.row += 1;
    context.column = 0;
    if (context.row > 24) {
        for (0..24) |i| {
            std.mem.copyForwards(u8, @volatileCast(&buffer[i]), @volatileCast(&buffer[i + 1]));
        }
        context.row -= 1;
        @memset(&buffer[24], 0);
    }
}

pub fn putCharAt(x: u8, y: u8, c: u8) void {
    buffer[y][x * 2] = c;
    buffer[y][x * 2 + 1] = context.color;
    setCursorPosition(x, y);
}

pub fn putChar(c: u8) void {
    if (c == '\n') {
        newLine();
        return;
    }
    if (context.column == 80) newLine();
    putCharAt(context.column, context.row, c);
    context.column += 1;
}

pub fn writeString(str: []const u8) !usize {
    for (str) |c| {
        putChar(c);
    }
    return str.len;
}

pub fn setCursor(enabled: bool) void {
    if (enabled) {
        // Tells the CRT Controller Address Register(0x3D4) that we will write to the Cursor Start Register(0xA)
        cpu.outb(0x3D4, 0x0A);
        // Gives the CRT Controller Data Register(0x3D5) a byte which
        // enables the cursor(sets the 3rd bit to 0) and sets the starting scanline to 14
        cpu.outb(0x3D5, 0x0E);

        // Does the same as above but with the Cursor End Register(0xB)
        cpu.outb(0x3D4, 0x0B);
        // Also same as above but scanline 15 is end line
        cpu.outb(0x3D5, 0x0F);
    } else {
        // Writes 0b0010000 to start register, disabling cursor
        cpu.outb(0x3D4, 0x0A);
        cpu.outb(0x3D5, 0x20);
    }
}

pub fn setCursorPosition(x: usize, y: usize) void {
    const position: u16 = @intCast((y * 80) + x);
    cpu.outb(0x3D4, 0x0F); // Cursor location low register
    cpu.outb(0x3D5, @intCast(position & 0xFF));
    cpu.outb(0x3D4, 0x0E); // Cursor location high register
    cpu.outb(0x3D5, @intCast((position >> 8) & 0xFF));
}
