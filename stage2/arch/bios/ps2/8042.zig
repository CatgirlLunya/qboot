const cpu = @import("../asm/cpu.zig");
const std = @import("std");

const DATA_PORT = 0x60;
const COMMAND_PORT = 0x64;
const STATUS_PORT = 0x64;

// Docs at https://stanislavs.org/helppc/8042.html
pub const Command = enum(u8) {
    read_config_byte = 0x20,
    write_config_byte = 0x60,
    disable_second_port = 0xA7,
    enable_second_port = 0xA8,
    test_second_port = 0xA9,
    test_ps2_controller = 0xAA,
    test_first_port = 0xAB,
    diagnostic_dump = 0xAC,
    disable_first_port = 0xAD,
    enable_first_port = 0xAE,
    read_controller_input_port = 0xC0,
    copy_bits_0_to_3 = 0xC1,
    copy_bits_4_to_7 = 0xC2,
    read_output_port = 0xD0,
    write_output_port = 0xD1,
    write_keyboard_output = 0xD2,
    write_auxiliary_output = 0xD3,
    write_auxiliary_device = 0xD4,
    read_test_inputs = 0xE0,
};

pub const DeviceCommand = enum(u8) {
    identify = 0xF2,
    enable_scanning = 0xF4,
    disable_scanning = 0xF5,
    reset = 0xFF,
};

pub const Device = enum {
    at_keyboard,
    standard_mouse,
    scroll_wheel_mouse,
    five_button_mouse,
    mf2_keyboard,
    short_keyboard,
    host_connected_keyboard,
    onetwentytwo_key_keyboard,
    japanese_g_keyboard,
    japanese_p_keyboard,
    japanese_a_keyboard,
    ncd_sun_keyboard,
};

pub const PS2Error = error{
    ControllerFailed,
    PortFailed,
    OutputFailed,
    InputFailed,
    ResetFailed,
    AckFailed,
    InvalidDevice,
};

var port2_available = false;

pub fn init() !void {
    try command(.disable_first_port, null);
    try command(.disable_second_port, null);

    _ = cpu.inb(DATA_PORT); // Flush the buffer

    try command(.read_config_byte, null);
    var configuration = try output();
    configuration &= ~@as(u8, 0b01000011); // Turn off bits 0, 1, and 6
    try command(.write_config_byte, configuration);

    port2_available = configuration & (1 << 5) == 1;

    // Self test
    try command(.test_ps2_controller, null);
    if (try output() != 0x55) return error.ControllerFailed;

    if (port2_available) {
        try command(.enable_second_port, null);
        try command(.read_config_byte, null);
        var config = try output();
        port2_available = config & (1 << 5) == 1;
        if (port2_available) try command(.disable_second_port, null);
    }

    // Port tests
    try command(.test_first_port, null);
    if (try output() != 0x00) return error.PortFailed;
    if (port2_available) {
        try command(.test_second_port, null);
        if (try output() != 0x00) return error.PortFailed;
    }

    // Enable interrupts
    try command(.read_config_byte, null);
    configuration = try output();
    configuration |= 0b1;
    if (port2_available) configuration |= 0b10;
    try command(.write_config_byte, configuration);

    // Enable ports
    try command(.enable_first_port, null);
    if (port2_available) try command(.enable_second_port, null);
}

pub fn deinit() !void {
    // Resets and disables ports
    try reset(0);
    try command(.disable_first_port, null);
    if (port2_available) {
        try reset(1);
        try command(.disable_second_port, null);
    }
}

pub fn reset(device: u8) !void {
    try deviceCommand(device, .reset);
    if (try output() != 0xFA) return error.AckFailed;
    if (try output() != 0xAA) return error.ResetFailed;
}

pub fn status() u8 {
    return cpu.inb(STATUS_PORT);
}

pub fn output() !u8 {
    try delay(.output);
    return cpu.inb(DATA_PORT);
}

pub fn command(instr: Command, data: ?u8) !void {
    try delay(.input);
    cpu.outb(COMMAND_PORT, @intFromEnum(instr));
    if (data) |d| {
        try delay(.input);
        cpu.outb(DATA_PORT, d);
    }
}

pub fn delay(io: enum { input, output }) !void {
    const max_delay = 10000;
    if (io == .input) {
        for (0..max_delay) |_| {
            if (status() & 0x2 == 0) return;
        }
        return error.InputFailed;
    } else {
        for (0..max_delay) |_| {
            if (status() & 0x1 == 1) return;
        }
        return error.OutputFailed;
    }
}

pub fn deviceCommand(device: u8, instr: DeviceCommand) !void {
    if (device == 0) {
        try delay(.input);
    } else if (device == 1) {
        try command(.write_auxiliary_device, null);
        try delay(.input);
    }
    cpu.outb(DATA_PORT, @intFromEnum(instr));
}

pub fn identify(device: u8) !Device {
    try deviceCommand(device, .disable_scanning);
    if (try output() != 0xFA) return error.AckFailed;
    try deviceCommand(device, .identify);
    if (try output() != 0xFA) return error.AckFailed;

    var arr: [2]u8 = undefined;
    arr[0] = output() catch 0xFF;
    arr[1] = output() catch 0xFF;
    try deviceCommand(device, .enable_scanning);
    if (try output() != 0xFA) return error.AckFailed;

    var int = std.mem.readInt(u16, &arr, .Big);
    // _ = output() catch null;
    return switch (int) {
        0xFFFF => .at_keyboard,
        0x00FF => .standard_mouse,
        0x03FF => .scroll_wheel_mouse,
        0x04FF => .five_button_mouse,
        0xAB83, 0xABC1 => .mf2_keyboard,
        0xAB84, 0xAB54 => .short_keyboard,
        0xAB85 => .host_connected_keyboard,
        0xAB86 => .onetwentytwo_key_keyboard,
        0xAB90 => .japanese_g_keyboard,
        0xAB91 => .japanese_p_keyboard,
        0xAB92 => .japanese_a_keyboard,
        0xACA1 => .ncd_sun_keyboard,
        else => {
            std.log.err("Invalid Device: 0x{x}", .{int});
            return error.InvalidDevice;
        },
    };
}
