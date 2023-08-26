const uefi = @import("std").os.uefi;
const protocol = @import("wrapper/protocol.zig");
const api_terminal = @import("../../api/api.zig").terminal;

var con_out: ?*uefi.protocols.SimpleTextOutputProtocol = null;

pub fn init() !void {
    con_out = try protocol.loadProtocol(uefi.protocols.SimpleTextOutputProtocol);
    if (con_out) |c| {
        try c.clearScreen().err();
        try c.enableCursor(true).err();
        try c.setCursorPosition(0, 0).err();
    } else {
        return uefi.Status.EfiError.ProtocolUnreachable;
    }
}

pub fn writeChar(char: u8) !void {
    if (con_out) |c| {
        if (char == '\n') try writeChar('\r');
        const utf16arr = [2]u16{ char, 0 };
        try c.outputString(@as(*const [1:0]u16, @ptrCast(&utf16arr))).err();
    }
}

pub fn setCursor(enabled: bool) void {
    if (con_out) |c| {
        try c.enableCursor(enabled).err();
    }
}

pub fn setCursorPosition(x: usize, y: usize) !void {
    if (con_out) |c| {
        try c.setCursorPosition(x, y).err();
    }
}

pub fn setColor(fg: api_terminal.fg_color, bg: api_terminal.bg_color) !void {
    if (con_out) |c| {
        try c.setAttribute(@intFromEnum(fg) | @intFromEnum(bg) << 4).err();
    }
}

pub fn writeString(str: []const u8) !usize {
    for (str) |c| {
        try writeChar(c);
    }
    return str.len;
}
