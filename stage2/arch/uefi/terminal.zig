const std = @import("std");
const uefi = std.os.uefi;

var con_out: ?*uefi.protocols.SimpleTextOutputProtocol = null;

pub fn init() bool {
    con_out = uefi.system_table.con_out;
    if (con_out) |c| {
        _ = c.clearScreen();
        _ = c.enableCursor(true);
        _ = c.setCursorPosition(0, 0);
        return true;
    }
    return false;
}

pub fn writeChar(char: u8) void {
    if (con_out) |c| {
        if (char == '\n') writeChar('\r');
        const utf16arr = [2]u16{ char, 0 };
        _ = c.outputString(@as(*const [1:0]u16, @ptrCast(&utf16arr)));
    }
}

pub fn newLine() void {
    writeChar('\n');
}

pub fn setCursor(enabled: bool) void {
    if (con_out) |c| {
        _ = c.enableCursor(enabled);
    }
}

pub fn setCursorPosition(x: usize, y: usize) void {
    if (con_out) |c| {
        _ = c.setCursorPosition(x, y);
    }
}

// zig fmt: off
pub const fg_color = enum(u8) {
    black = 0,
    blue,
    green,
    cyan,
    red,
    magenta,
    brown,
    gray,
    drak_gray,
    light_blue,
    light_green,
    light_cyan,
    light_red,
    light_magenta,
    yellow,
    white
};

pub const bg_color = enum(u8) {
    black = 0,
    blue,
    green,
    cyan,
    red,
    magenta,
    brown,
    gray
};
// zig fmt: on

pub fn setColor(fg: fg_color, bg: bg_color) void {
    if (con_out) |c| {
        _ = c.setAttribute(@intFromEnum(fg) | @intFromEnum(bg) << 4);
    }
}

pub fn writeString(str: []const u8) void {
    for (str) |c| {
        writeChar(c);
    }
}
