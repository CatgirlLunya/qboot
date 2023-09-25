const uefi = @import("std").os.uefi;
pub const Time = @import("api").clock.Time;

pub fn getTime() !Time {
    var time: uefi.Time = undefined;
    var status = uefi.system_table.runtime_services.getTime(&time, null);
    try status.err();
    return .{
        .h = time.hour,
        .m = time.minute,
        .s = time.second,
    };
}
