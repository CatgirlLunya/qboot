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

pub const Terminal = struct {
    init: ?*const fn () anyerror!void,
    writeStr: *const fn ([]const u8) anyerror!usize,
    setColor: ?*const fn (fg_color, bg_color) anyerror!void,
};
