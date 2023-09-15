const keyboard = @import("../../api/keyboard.zig");
const uefi = @import("std").os.uefi;
const protocol = @import("wrapper/protocol.zig");

var in_ext: ?*uefi.protocols.SimpleTextInputExProtocol = null;

pub fn init() !void {
    in_ext = try protocol.loadProtocol(uefi.protocols.SimpleTextInputExProtocol);
    try in_ext.?.reset(true).err();
}

pub fn getInput() ?keyboard.KeyEvent {
    var data: uefi.protocols.KeyData = undefined;
    var event: keyboard.KeyEvent = .{};
    if (in_ext) |in| {
        in.readKeyStrokeEx(&data).err() catch return null;
        if (data.key.unicode_char == 0) {
            event.code = .{ .function = switch (data.key.scan_code) {
                1 => .up,
                2 => .down,
                3 => .right,
                4 => .left,
                5 => .home,
                6 => .end,
                7 => .insert,
                8 => .delete,
                9 => .page_up,
                10 => .page_down,
                11 => .F1,
                12 => .F2,
                13 => .F3,
                14 => .F4,
                15 => .F5,
                16 => .F6,
                17 => .F7,
                18 => .F8,
                19 => .F9,
                20 => .F10,
                21 => .F11,
                22 => .F12,
                23 => .escape,
                0x7F => .multimedia_mute,
                0x80 => .multimedia_volume_up,
                0x81 => .multimedia_volume_down,
                0x100 => .brightness_up,
                0x101 => .brightness_down,
                0x102 => .hibernate,
                0x103 => .acpi_sleep,
                0x104 => .toggle_display,
                0x105 => .recovery,
                0x106 => .eject,
                else => return null,
            } };
        } else {
            event.code = .{ .printable = switch (data.key.unicode_char) {
                0x9 => '\t',
                0xA => '\n',
                0xD => '\n',
                else => data.key.unicode_char,
            } };
        }
        return event;
        // TODO: Translate modifiers into event
    }
    return null;
}
