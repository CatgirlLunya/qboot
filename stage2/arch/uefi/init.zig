const exceptions = @import("exceptions.zig");
const uefi = @import("std").os.uefi;

pub fn init() !void {
    try exceptions.init();
    try uefi.system_table.boot_services.?.setWatchdogTimer(0, 0, 0, null).err();
}
