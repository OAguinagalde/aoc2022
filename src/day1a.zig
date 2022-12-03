const std = @import("std");

// TODO how the hell can I embed the file if its in a folder "out of the package"?
// 
//     const input = @embedFile("../input/1/input.txt");
// 
// Aparently I can make a link and that would work, not a fan of that tho...

pub fn run() !void {
    var file = try std.fs.cwd().openFile("input/1/input.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    
    var elf_index: u32 = 0;
    var elf_calories: u32 = 0;
    
    var current_line_number: u32 = 1;
    
    var max_calories: u32 = 0;
    var max_calories_index: u32 = 0;
    var max_calories_index_line: u32 = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |slice| {
        if (!std.mem.eql(u8, slice, "")) {
            var number = try std.fmt.parseInt(u32, slice, 10);
            elf_calories += number;
        }
        else {
            if (elf_calories > max_calories) {
                max_calories = elf_calories;
                max_calories_index  = elf_index;
                max_calories_index_line = current_line_number;
            }
            elf_index += 1;
            elf_calories = 0;
        }
        current_line_number += 1;
    }

    // std.debug.print("max_calories: {d} max_calories_index: {d} max_calories_index_line: {d}\n", .{max_calories, max_calories_index, max_calories_index_line});
    std.debug.print("1a -> {d}\n", .{max_calories});
}
