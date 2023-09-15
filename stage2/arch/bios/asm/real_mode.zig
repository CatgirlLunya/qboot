pub const frame = @import("frame.zig");

pub extern fn biosInterrupt(number: u8, input: *frame.Frame, output: *frame.Frame) callconv(.C) void;
