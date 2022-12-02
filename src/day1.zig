const std = @import("std");

// TODO how the hell can I embed the file if its in a folder "out of the package"?
// 
//     const input = @embedFile("../input/1/input.txt");
// 

pub fn run() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    var file = try std.fs.cwd().openFile("input/1/input.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var line_count: u32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |slice| {
        // try stdout.print("line: {s}\n", .{slice});
        var is_empty = std.mem.eql(u8, slice, "");
        var is_new_line = std.mem.eql(u8, slice, "\n");
        if (!is_empty and !is_new_line) {
            var number = try std.fmt.parseInt(u32, slice, 10);
            if (number == undefined) {}
            try stdout.print("number: {}\n", .{number});
        }
        else {
            try stdout.print("new line\n", .{});
        }
        line_count += 1;
    }
    try stdout.print("total lines {}\n", .{line_count});
    
    // TODO Why in the hell would this not work?
    // What does "unable to resolve comptime value" even mean here?
    // Why would debug printing need the value of a string during compile time?
    // 
    //     std.debug.print(slice, .{});
    // 

}
