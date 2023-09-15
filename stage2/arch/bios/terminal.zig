const cpu = @import("asm/cpu.zig");
const api_terminal = @import("../../api/api.zig").terminal;
const std = @import("std");

const buffer: *volatile [25][160]u8 = @ptrFromInt(0xB8000);
// Faster for backspaces than iterating through the previous row to find the last character if needed
var position_per_row: [25]u8 = [_]u8{0} ** 25;

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

fn newLine() void {
    context.row += 1;
    if (context.row > 24) {
        for (0..24) |y| {
            for (0..160) |x| {
                buffer[y][x] = buffer[y + 1][x];
            }
            position_per_row[y] = position_per_row[y + 1];
        }
        context.row -= 1;
        @memset(&buffer[24], 0);
    }
    position_per_row[context.row - 1] = context.column;
    context.column = 0;
    setCursorPosition(0, context.row);
}

fn putCharAt(x: u8, y: u8, c: u8) void {
    buffer[y][x * 2] = c;
    buffer[y][x * 2 + 1] = context.color;
    setCursorPosition(x + 1, y);
}

fn backspace() void {
    if (context.column == 0) {
        if (context.row == 0) return;
        context.row -= 1;
        context.column = position_per_row[context.row];
    } else {
        context.column -= 1;
    }
    putCharAt(context.column, context.row, 0);
    setCursorPosition(context.column, context.row);
}

pub fn putChar(c: u8) !void {
    if (c == @intFromEnum(api_terminal.SpecialChars.newline)) {
        newLine();
    } else if (c == @intFromEnum(api_terminal.SpecialChars.backspace)) {
        backspace();
    } else if (c == @intFromEnum(api_terminal.SpecialChars.tab)) {
        for (0..4) |_| try putChar(' ');
    } else {
        if (context.column == 80) newLine();
        putCharAt(context.column, context.row, c);
        context.column += 1;
    }
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
