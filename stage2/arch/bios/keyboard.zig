const isr = @import("asm/isr.zig");
const ps2 = @import("ps2/8042.zig");
const pic = @import("asm/pic.zig");
const keyboard = @import("../../api/keyboard.zig");
const std = @import("std");

// Both of the following use keycode set 2
// Table that translates the first byte of a key code into a scancode
const byte1_table = [_]keyboard.Scancode{
    .invalid,      .F9,          .invalid,     .F5,
    .F3,           .F1,          .F2,          .F12,
    .invalid,      .F10,         .F8,          .F6,
    .F4,           .tab,         .back_tick,   .invalid,
    .invalid,      .alt_left,    .shift_left,  .invalid,
    .control_left, .ch_q,        .ch_1,        .invalid,
    .invalid,      .invalid,     .ch_z,        .ch_s,
    .ch_a,         .ch_w,        .ch_2,        .invalid,
    .invalid,      .ch_c,        .ch_x,        .ch_d,
    .ch_e,         .ch_4,        .ch_3,        .invalid,
    .invalid,      .space,       .ch_v,        .ch_f,
    .ch_t,         .ch_r,        .ch_5,        .invalid,
    .invalid,      .ch_n,        .ch_b,        .ch_h,
    .ch_g,         .ch_y,        .ch_6,        .invalid,
    .invalid,      .invalid,     .ch_m,        .ch_j,
    .ch_u,         .ch_7,        .ch_8,        .invalid,
    .invalid,      .comma,       .ch_k,        .ch_i,
    .ch_o,         .ch_0,        .ch_9,        .invalid,
    .invalid,      .period,      .slash,       .ch_l,
    .semicolon,    .ch_p,        .minus,       .invalid,
    .invalid,      .invalid,     .apostrophe,  .invalid,
    .bracket_left, .equals,      .invalid,     .invalid,
    .caps_lock,    .shift_right, .enter,       .bracket_right,
    .invalid,      .backslash,   .invalid,     .invalid,
    .invalid,      .invalid,     .invalid,     .invalid,
    .invalid,      .invalid,     .backspace,   .invalid,
    .invalid,      .kp_1,        .invalid,     .kp_4,
    .kp_7,         .invalid,     .invalid,     .invalid,
    .kp_0,         .kp_period,   .kp_2,        .kp_5,
    .kp_6,         .kp_8,        .escape,      .number_lock,
    .F11,          .kp_plus,     .kp_3,        .kp_minus,
    .kp_asterisk,  .kp_9,        .scroll_lock, .invalid,
    .invalid,      .invalid,     .invalid,     .F7,
};
// Table that translates the second byte of a key code into a scancode, if the first byte is 0xE0
const byte2_table = [_]keyboard.Scancode{
    .invalid,              .invalid,                   .invalid,              .invalid,
    .invalid,              .invalid,                   .invalid,              .invalid,
    .invalid,              .invalid,                   .invalid,              .invalid,
    .invalid,              .invalid,                   .invalid,              .invalid,

    .multimedia_search,    .alt_right,                 .invalid,              .invalid,
    .control_right,        .multimedia_previous_track, .invalid,              .invalid,
    .multimedia_favorites, .invalid,                   .invalid,              .invalid,
    .invalid,              .invalid,                   .invalid,              .left_gui,

    .multimedia_refresh,   .multimedia_volume_down,    .invalid,              .multimedia_mute,
    .invalid,              .invalid,                   .invalid,              .right_gui,
    .multimedia_stop,      .invalid,                   .invalid,              .multimedia_calculator,
    .invalid,              .invalid,                   .invalid,              .apps,

    .multimedia_forward,   .invalid,                   .multimedia_volume_up, .invalid,
    .multimedia_pause,     .invalid,                   .invalid,              .acpi_power,
    .multimedia_back,      .invalid,                   .multimedia_home,      .multimedia_stop,
    .invalid,              .invalid,                   .invalid,              .acpi_sleep,

    .multimedia_computer,  .invalid,                   .invalid,              .invalid,
    .invalid,              .invalid,                   .invalid,              .invalid,
    .multimedia_email,     .invalid,                   .kp_slash,             .invalid,
    .invalid,              .multimedia_next_track,     .invalid,              .invalid,

    .multimedia_select,    .invalid,                   .invalid,              .invalid,
    .invalid,              .invalid,                   .invalid,              .invalid,
    .invalid,              .invalid,                   .kp_enter,             .invalid,
    .invalid,              .invalid,                   .acpi_wake,            .invalid,

    .invalid,              .invalid,                   .invalid,              .invalid,
    .invalid,              .invalid,                   .invalid,              .invalid,
    .invalid,              .end,                       .invalid,              .left,
    .home,                 .invalid,                   .invalid,              .invalid,

    .insert,               .delete,                    .down,                 .invalid,
    .right,                .up,                        .invalid,              .invalid,
    .invalid,              .invalid,                   .page_down,            .invalid,
    .invalid,              .page_up,                   .invalid,              .invalid,
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
    asm volatile ("sti");
}

pub fn deinit() !void {
    asm volatile ("cli");
    pic.uninstallIRQ(0x1);
    asm volatile ("sti");
}

var current_modifiers: keyboard.KeyEvent.Modifiers = .{};

pub fn eventFromKeycode(code: [8]?u8) ?keyboard.KeyEvent {
    // No switch on optionals is sad
    if (code[0] == null) return null;
    return switch (code[0].?) {
        0...0x83 => .{ .code = byte1_table[code[0].?], .event_type = .pressed },
        0xE0 => {
            if (code[1] == null) return null;
            return switch (code[1].?) {
                0...0x11, 0x13...0x7F => .{ .code = byte2_table[code[1].?], .event_type = .pressed },
                0x12 => {
                    if (code[2] == null or code[3] == null) return null;
                    if (code[2].? == 0xE0 and code[3].? == 0x7C) return .{ .code = .print_screen, .event_type = .pressed };
                    return null;
                },
                0xF0 => {
                    if (code[2] == null) return null;
                    return switch (code[2].?) {
                        0...0x7B, 0x7D...0x7F => .{ .code = byte2_table[code[2].?], .event_type = .released },
                        0x7C => {
                            if (code[3] == null or code[4] == null or code[5] == null) return null;
                            if (code[3].? == 0xE0 and code[4].? == 0xF0 and code[5].? == 0x12) return .{ .code = .print_screen, .event_type = .released };
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
            return .{ .code = .pause, .event_type = .pressed };
        },
        0xF0 => {
            if (code[1] == null) return null;
            return .{ .code = byte1_table[code[1].?], .event_type = .released };
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
        if (e.code == .alt_left or e.code == .alt_right) {
            current_modifiers.alt = e.event_type == .pressed;
        }
        if (e.code == .control_left or e.code == .control_right) {
            current_modifiers.ctrl = e.event_type == .pressed;
        }
        if (e.code == .shift_left or e.code == .shift_right) {
            current_modifiers.shift = e.event_type == .pressed;
        }
        e.modifiers = current_modifiers;

        buffer[top] = e.*;
        top = @addWithOverflow(top, 1)[0];
    }

    pic.eoi(@intCast(info.interrupt_number - pic.PIC1_OFFSET));
}

pub fn getInput() ?keyboard.KeyEvent {
    // Wait until buffer at head has data, then return it and advance head
    if (top == head) return null;
    asm volatile ("nop"); // For some reason bochs doesn't work at all without this but works perfectly with it so don't remove
    head = @addWithOverflow(head, 1)[0];
    return buffer[head - 1];
}
