pub const Time = struct {
    h: u32,
    m: u32,
    s: u32,
};

pub const Clock = struct {
    getTime: *const fn () anyerror!Time,
};
