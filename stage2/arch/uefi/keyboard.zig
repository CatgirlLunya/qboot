const keyboard = @import("../../api/keyboard.zig");
const uefi = @import("std").os.uefi;

pub fn getInput() ?keyboard.KeyEvent {
    var data: uefi.protocols.InputKey = undefined;
    if (uefi.system_table.con_in) |in| {
        in.readKeyStroke(&data).err() catch return null;
        // TODO: Implement table translating unicode chars and scancodes to keyboard scancodes
    }
    return null;
}
