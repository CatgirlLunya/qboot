const uefi = @import("std").os.uefi;

pub const Clock = struct {
    s: u32,
    m: u32,
    h: u32,
};

pub fn getTime() !Clock {
    var time: uefi.Time = undefined;
    var status = uefi.system_table.runtime_services.getTime(&time, null);
    try status.err();
    return .{
        .h = time.hour,
        .m = time.minute,
        .s = time.second,
    };
}
