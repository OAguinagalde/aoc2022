const std = @import("std");

pub fn run() !void {
    var file = try std.fs.cwd().openFile("input/1/input.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    
    var elf_calories: u32 = 0;
    
    var max_calories_first: u32 = 0;
    var max_calories_second: u32 = 0;
    var max_calories_third: u32 = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |slice| {
        if (!std.mem.eql(u8, slice, "")) {
            var number = try std.fmt.parseInt(u32, slice, 10);
            elf_calories += number;
        }
        else {
            
            if (elf_calories > max_calories_first) {
                max_calories_third = max_calories_second;
                max_calories_second = max_calories_first;
                max_calories_first = elf_calories;
            }
            else if (elf_calories > max_calories_second) {
                max_calories_third = max_calories_second;
                max_calories_second = elf_calories;
            }
            else if (elf_calories > max_calories_third) {
                max_calories_third = elf_calories;
            }

            elf_calories = 0;
        }
    }

    std.debug.print("1st {d} 2nd {d} 3rd {d}\n", .{max_calories_first, max_calories_second, max_calories_third});
    std.debug.print("The answer for day 1b {d}\n", .{max_calories_first + max_calories_second + max_calories_third});
}
