const std = @import("std");

const day1a = @import("day1a.zig");
const day1b = @import("day1b.zig");

const day2a = @import("day2a.zig");
const day2b = @import("day2b.zig");

const day3a = @import("day3a.zig");
const day3b = @import("day3b.zig");

const day4a = @import("day4a.zig");
const day4b = @import("day4b.zig");

const day5a = @import("day5a.zig");
const day5b = @import("day5b.zig");

const day6a = @import("day6a.zig");
const day6b = @import("day6b.zig");

pub fn main() !void {
    // try day1a.run();
    // try day1b.run();
    // try day2a.run();
    // try day2b.run();
    // try day3a.run();
    // try day3b.run();
    // try day4a.run();
    // try day4b.run();
    // try day5a.run();
    // try day5b.run();
    try day6a.run();
    try day6b.run();
}

pub fn default_main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
