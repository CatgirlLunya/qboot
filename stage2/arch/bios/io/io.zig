const api = @import("api");
pub const terminal = @import("terminal.zig");
pub const serial = @import("serial.zig");

pub const terminal_interface: api.terminal.Terminal = .{
    .init = terminal.init,
    .setColor = terminal.setColor,
    .printChar = terminal.printChar,
};

pub const serial_interface: api.terminal.Terminal = .{
    .init = serial.init,
    .setColor = serial.setColor,
    .printChar = serial.printChar,
};
