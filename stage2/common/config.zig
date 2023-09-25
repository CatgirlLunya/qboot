pub const PrideFlag = enum(u8) {
    none,
    gay,
    bi,
    trans,
};

pub const Config = struct {
    kernel_path: [*:'\n']u8,
    pride_flag: PrideFlag,
};
