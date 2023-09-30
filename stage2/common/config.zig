const std = @import("std");

pub const PrideFlag = enum(u8) {
    none,
    gay,
    bi,
    trans,
};

pub const Error = error{
    InvalidKey,
    InvalidValue,
    NoValue,
};

pub const Config = struct {
    kernel_path: []u8,
    flag: PrideFlag = .none,

    fn sanitizeString(allocator: std.mem.Allocator, str: []const u8) ![]u8 {
        var sanitized = try allocator.alloc(u8, str.len);
        const removed = std.mem.replace(u8, str, " ", "", sanitized);
        sanitized = try allocator.realloc(sanitized, str.len - removed);
        sanitized = std.ascii.lowerString(sanitized, sanitized);
        return sanitized;
    }

    fn handleFlag(config: *Config, value: []u8) !void {
        config.flag = blk: {
            if (eql(value, "bi")) break :blk .bi;
            if (eql(value, "trans")) break :blk .trans;
            if (eql(value, "gay")) break :blk .gay;
        };
    }

    fn handlePath(config: *Config, allocator: std.mem.Allocator, value: []u8) !void {
        var dup = try allocator.dupe(u8, value);
        config.kernel_path = dup;
    }

    // Helper function to be short
    fn eql(str1: []const u8, str2: []const u8) bool {
        return std.mem.eql(u8, str1, str2);
    }

    pub fn readFromBin(allocator: std.mem.Allocator, bin: []u8) !Config {
        var iter = std.mem.splitScalar(u8, bin, '\n');
        var config: Config = undefined;
        while (iter.next()) |line| {
            var split_line = std.mem.splitScalar(u8, line, ':');

            const key = split_line.first();
            var sanitized_key = try sanitizeString(allocator, key);
            defer allocator.free(sanitized_key);
            const value = if (split_line.next()) |value| value else return error.NoValue;
            var sanitized_value = try sanitizeString(allocator, value);
            defer allocator.free(sanitized_value);

            if (eql(sanitized_key, "flag")) {
                try config.handleFlag(sanitized_value);
            } else if (eql(sanitized_key, "path")) {
                try config.handlePath(allocator, sanitized_value);
            } else {
                return error.InvalidKey;
            }
        }
        return config;
    }

    pub fn free(self: *Config, allocator: std.mem.Allocator) void {
        allocator.free(self.kernel_path);
    }
};
