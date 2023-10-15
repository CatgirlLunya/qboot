const isr = @import("asm/isr.zig");
const ps2 = @import("ps2/8042.zig");
const pic = @import("asm/pic.zig");
const keyboard = @import("api").keyboard;
const std = @import("std");

// Both of the following use keycode set 2
// Table that translates the first byte of a key code into a scancode
const byte1_table = [_]?keyboard.Scancode{
    null,                           .{ .function = .F9 },          null,                          .{ .function = .F5 },
    .{ .function = .F3 },           .{ .function = .F1 },          .{ .function = .F2 },          .{ .function = .F12 },
    null,                           .{ .function = .F10 },         .{ .function = .F8 },          .{ .function = .F6 },
    .{ .function = .F4 },           .{ .printable = '\t' },        .{ .printable = '`' },         null,
    null,                           .{ .function = .alt_left },    .{ .function = .shift_left },  null,
    .{ .function = .control_left }, .{ .printable = 'q' },         .{ .printable = '1' },         null,
    null,                           null,                          .{ .printable = 'z' },         .{ .printable = 's' },
    .{ .printable = 'a' },          .{ .printable = 'w' },         .{ .printable = '2' },         null,
    null,                           .{ .printable = 'c' },         .{ .printable = 'x' },         .{ .printable = 'd' },
    .{ .printable = 'e' },          .{ .printable = '4' },         .{ .printable = '3' },         null,
    null,                           .{ .printable = ' ' },         .{ .printable = 'v' },         .{ .printable = 'f' },
    .{ .printable = 't' },          .{ .printable = 'r' },         .{ .printable = '5' },         null,
    null,                           .{ .printable = 'n' },         .{ .printable = 'b' },         .{ .printable = 'h' },
    .{ .printable = 'g' },          .{ .printable = 'y' },         .{ .printable = '6' },         null,
    null,                           null,                          .{ .printable = 'm' },         .{ .printable = 'j' },
    .{ .printable = 'u' },          .{ .printable = '7' },         .{ .printable = '8' },         null,
    null,                           .{ .printable = ',' },         .{ .printable = 'k' },         .{ .printable = 'i' },
    .{ .printable = 'o' },          .{ .printable = '0' },         .{ .printable = '9' },         null,
    null,                           .{ .printable = '.' },         .{ .printable = '/' },         .{ .printable = 'l' },
    .{ .printable = ';' },          .{ .printable = 'p' },         .{ .printable = '-' },         null,
    null,                           null,                          .{ .printable = '\'' },        null,
    .{ .printable = '[' },          .{ .printable = '=' },         null,                          null,
    .{ .function = .caps_lock },    .{ .function = .shift_right }, .{ .printable = '\n' },        .{ .printable = ']' },
    null,                           .{ .printable = '\\' },        null,                          null,
    null,                           null,                          null,                          null,
    null,                           null,                          .{ .printable = 8 },           null,
    null,                           .{ .printable = '1' },         null,                          .{ .printable = '4' },
    .{ .printable = '7' },          null,                          null,                          null,
    .{ .printable = '0' },          .{ .printable = '.' },         .{ .printable = '2' },         .{ .printable = '5' },
    .{ .printable = '6' },          .{ .printable = '8' },         .{ .function = .escape },      .{ .function = .number_lock },
    .{ .function = .F11 },          .{ .printable = '+' },         .{ .printable = '3' },         .{ .printable = '-' },
    .{ .printable = '*' },          .{ .printable = '9' },         .{ .function = .scroll_lock }, null,
    null,                           null,                          null,                          .{ .function = .F7 },
};

const byte1_table_shift = [_]?keyboard.Scancode{
    null,                           .{ .function = .F9 },          null,                          .{ .function = .F5 },
    .{ .function = .F3 },           .{ .function = .F1 },          .{ .function = .F2 },          .{ .function = .F12 },
    null,                           .{ .function = .F10 },         .{ .function = .F8 },          .{ .function = .F6 },
    .{ .function = .F4 },           .{ .printable = '\t' },        .{ .printable = '~' },         null,
    null,                           .{ .function = .alt_left },    .{ .function = .shift_left },  null,
    .{ .function = .control_left }, .{ .printable = 'Q' },         .{ .printable = '!' },         null,
    null,                           null,                          .{ .printable = 'Z' },         .{ .printable = 'S' },
    .{ .printable = 'A' },          .{ .printable = 'W' },         .{ .printable = '@' },         null,
    null,                           .{ .printable = 'C' },         .{ .printable = 'X' },         .{ .printable = 'D' },
    .{ .printable = 'E' },          .{ .printable = '$' },         .{ .printable = '#' },         null,
    null,                           .{ .printable = ' ' },         .{ .printable = 'V' },         .{ .printable = 'F' },
    .{ .printable = 'T' },          .{ .printable = 'R' },         .{ .printable = '%' },         null,
    null,                           .{ .printable = 'N' },         .{ .printable = 'B' },         .{ .printable = 'H' },
    .{ .printable = 'G' },          .{ .printable = 'Y' },         .{ .printable = '^' },         null,
    null,                           null,                          .{ .printable = 'M' },         .{ .printable = 'J' },
    .{ .printable = 'U' },          .{ .printable = '&' },         .{ .printable = '*' },         null,
    null,                           .{ .printable = '<' },         .{ .printable = 'K' },         .{ .printable = 'I' },
    .{ .printable = 'O' },          .{ .printable = ')' },         .{ .printable = '(' },         null,
    null,                           .{ .printable = '>' },         .{ .printable = '?' },         .{ .printable = 'L' },
    .{ .printable = ':' },          .{ .printable = 'P' },         .{ .printable = '_' },         null,
    null,                           null,                          .{ .printable = '"' },         null,
    .{ .printable = '{' },          .{ .printable = '+' },         null,                          null,
    .{ .function = .caps_lock },    .{ .function = .shift_right }, .{ .printable = '\n' },        .{ .printable = '}' },
    null,                           .{ .printable = '|' },         null,                          null,
    null,                           null,                          null,                          null,
    null,                           null,                          .{ .printable = 8 },           null,
    // The following is the keypad, and so is not modified by shift
    null,                           .{ .printable = '1' },         null,                          .{ .printable = '4' },
    .{ .printable = '7' },          null,                          null,                          null,
    .{ .printable = '0' },          .{ .printable = '.' },         .{ .printable = '2' },         .{ .printable = '5' },
    .{ .printable = '6' },          .{ .printable = '8' },         .{ .function = .escape },      .{ .function = .number_lock },
    .{ .function = .F11 },          .{ .printable = '+' },         .{ .printable = '3' },         .{ .printable = '-' },
    .{ .printable = '*' },          .{ .printable = '9' },         .{ .function = .scroll_lock }, null,
    null,                           null,                          null,                          .{ .function = .F7 },
};

// Table that translates the second byte of a key code into a scancode, if the first byte is 0xE0
const byte2_table = [_]?keyboard.Scancode{
    null,                                   null,                                        null,                                   null,
    null,                                   null,                                        null,                                   null,
    null,                                   null,                                        null,                                   null,
    null,                                   null,                                        null,                                   null,

    .{ .function = .multimedia_search },    .{ .function = .alt_right },                 null,                                   null,
    .{ .function = .control_right },        .{ .function = .multimedia_previous_track }, null,                                   null,
    .{ .function = .multimedia_favorites }, null,                                        null,                                   null,
    null,                                   null,                                        null,                                   .{ .function = .left_gui },

    .{ .function = .multimedia_refresh },   .{ .function = .multimedia_volume_down },    null,                                   .{ .function = .multimedia_mute },
    null,                                   null,                                        null,                                   .{ .function = .right_gui },
    .{ .function = .multimedia_stop },      null,                                        null,                                   .{ .function = .multimedia_calculator },
    null,                                   null,                                        null,                                   .{ .function = .apps },

    .{ .function = .multimedia_forward },   null,                                        .{ .function = .multimedia_volume_up }, null,
    .{ .function = .multimedia_pause },     null,                                        null,                                   .{ .function = .acpi_power },
    .{ .function = .multimedia_back },      null,                                        .{ .function = .multimedia_home },      .{ .function = .multimedia_stop },
    null,                                   null,                                        null,                                   .{ .function = .acpi_sleep },

    .{ .function = .multimedia_computer },  null,                                        null,                                   null,
    null,                                   null,                                        null,                                   null,
    .{ .function = .multimedia_email },     null,                                        .{ .printable = '/' },                  null,
    null,                                   .{ .function = .multimedia_next_track },     null,                                   null,

    .{ .function = .multimedia_select },    null,                                        null,                                   null,
    null,                                   null,                                        null,                                   null,
    null,                                   null,                                        .{ .printable = '\n' },                 null,
    null,                                   null,                                        .{ .function = .acpi_wake },            null,

    null,                                   null,                                        null,                                   null,
    null,                                   null,                                        null,                                   null,
    null,                                   .{ .function = .end },                       null,                                   .{ .function = .left },
    .{ .function = .home },                 null,                                        null,                                   null,

    .{ .function = .insert },               .{ .function = .delete },                    .{ .function = .down },                 null,
    .{ .function = .right },                .{ .function = .up },                        null,                                   null,
    null,                                   null,                                        .{ .function = .page_down },            null,
    null,                                   .{ .function = .page_up },                   null,                                   null,
};

var buffer: [256]keyboard.KeyEvent = [_]keyboard.KeyEvent{.{}} ** 256;
var buf: [8]?u8 = [_]?u8{null} ** 8;
var head: u8 = 0;
var top: u8 = 0;

pub fn init() !void {
    asm volatile ("cli");
    if (try ps2.identify(0) == .mf2_keyboard) {
        pic.installIRQ(0x1, keyboardIRQ);
    } else if (try ps2.identify(1) == .mf2_keyboard) {
        pic.installIRQ(0x9, keyboardIRQ);
    }
    // TODO: FIX?
    // asm volatile ("sti");
}

pub fn deinit() !void {
    asm volatile ("cli");
    pic.uninstallIRQ(0x1);
    asm volatile ("sti");
}

var current_modifiers: keyboard.KeyEvent.Modifiers = .{};

fn getCharFromByte(table: u8, index: u8) ?keyboard.Scancode {
    if (table == 1) {
        if (current_modifiers.shift) return byte1_table_shift[index];
        return byte1_table[index];
    } else if (table == 2) {
        return byte2_table[index];
    }
    return null;
}

pub fn eventFromKeycode(code: [8]?u8) ?keyboard.KeyEvent {
    // No switch on optionals is sad
    if (code[0] == null) return null;
    return switch (code[0].?) {
        0...0x83 => |ch| .{ .code = if (getCharFromByte(1, ch)) |scan| scan else {
            return null;
        }, .event_type = .pressed },
        0xE0 => {
            if (code[1] == null) return null;
            return switch (code[1].?) {
                0...0x11, 0x13...0x7F => |ch| .{ .code = if (getCharFromByte(2, ch)) |scan| blk: {
                    if (ch == 0x4A) break :blk if (current_modifiers.shift) .{ .printable = '?' } else .{ .printable = '/' };
                    break :blk scan;
                } else {
                    return null;
                }, .event_type = .pressed },
                0x12 => {
                    if (code[2] == null or code[3] == null) return null;
                    if (code[2].? == 0xE0 and code[3].? == 0x7C) return .{ .code = .{ .function = .print_screen }, .event_type = .pressed };
                    return null;
                },
                0xF0 => {
                    if (code[2] == null) return null;
                    return switch (code[2].?) {
                        0...0x7B, 0x7D...0x7F => |ch| .{ .code = if (getCharFromByte(2, ch)) |scan| blk: {
                            if (ch == 0x4A) break :blk if (current_modifiers.shift) .{ .printable = '?' } else .{ .printable = '/' };
                            break :blk scan;
                        } else {
                            return null;
                        }, .event_type = .released },
                        0x7C => {
                            if (code[3] == null or code[4] == null or code[5] == null) return null;
                            if (code[3].? == 0xE0 and code[4].? == 0xF0 and code[5].? == 0x12) return .{ .code = .{ .function = .print_screen }, .event_type = .released };
                            return null;
                        },
                        else => null,
                    };
                },
                else => null,
            };
        },
        0xE1 => {
            const c = [_]u8{ 0x14, 0x77, 0xE1, 0xF0, 0x14, 0xF0, 0x77 };
            for (1..8) |i| {
                if (code[i] == null) return null;
                if (code[i].? == c[i - 1]) return null;
            }
            return .{ .code = .{ .function = .pause }, .event_type = .pressed };
        },
        0xF0 => {
            if (code[1] == null) return null;
            return .{ .code = if (getCharFromByte(1, code[1].?)) |scan| scan else {
                return null;
            }, .event_type = .released };
        },
        else => null,
    };
}

fn keyboardIRQ(info: isr.InterruptInfo) callconv(.C) void {
    buf = [_]?u8{null} ** 8;
    for (0..8) |i| {
        buf[i] = ps2.output() catch null;
        if (buf[i] == null) break;
    }

    var event = eventFromKeycode(buf);

    if (event) |*e| {
        if (e.code.function == .alt_left or e.code.function == .alt_right) {
            current_modifiers.alt = e.event_type == .pressed;
        }
        if (e.code.function == .control_left or e.code.function == .control_right) {
            current_modifiers.ctrl = e.event_type == .pressed;
        }
        if (e.code.function == .shift_left or e.code.function == .shift_right) {
            current_modifiers.shift = !current_modifiers.shift;
        }
        if (e.code.function == .caps_lock and e.event_type == .pressed) {
            current_modifiers.shift = !current_modifiers.shift;
        }
        e.modifiers = current_modifiers;

        buffer[top] = e.*;
        // Wrapping addition
        top +%= 1;
    }
    pic.eoi(@intCast(info.interrupt_number - pic.PIC1_OFFSET));
}

pub fn getInput() ?keyboard.KeyEvent {
    // Wait until buffer at head has data, then return it and advance head
    if (top == head) return null;
    head +%= 1;
    return buffer[head - 1];
}
