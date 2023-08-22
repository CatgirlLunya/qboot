const real_mode = @import("asm/real_mode.zig");
const frame = @import("asm/frame.zig");

pub const Clock = struct {
    s: u32,
    m: u32,
    h: u32,
};

pub fn getTime() !Clock {
    var input_frame: frame.Frame = .{};
    input_frame.eax = 10;
    real_mode.biosInterrupt(0x1A, &input_frame, &input_frame);

    const ticks = input_frame.ecx * (1 << 16) + input_frame.edx;
    const total_seconds = @as(u32, @intFromFloat(@as(f32, @floatFromInt(ticks)) / 18.206));
    // zig fmt: off
    var clock: Clock = undefined; 
    clock.h = @divTrunc(total_seconds, 3600);
    clock.m = @divTrunc(total_seconds % 3600, 60);
    clock.s = ((total_seconds % (3600)) % 60);
    // zig fmt: on
    return clock;
}
