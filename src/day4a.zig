const std = @import("std");

const Range = struct {
    start: u32 = 0,
    end: u32 = 0
};

const InputLine = struct {
    range1: Range = Range {},
    range2: Range = Range {}
};

// TODO this feels quite overkill to parse a dead simple line of input...
// It works, but there must be better ways of going about it...
fn parse_input_line(line: []u8) !InputLine {
    
    const CurrentlyParsing = enum { RangeStart, RangeEnd };
    
    var currently_parsing: CurrentlyParsing = .RangeStart;
    var range_start_index: u32 = 0;
    var range_start: [10]u8 = std.mem.zeroes([10]u8);
    var range_end_index: u32 = 0;
    var range_end: [10]u8 = std.mem.zeroes([10]u8);

    var input_line: InputLine = InputLine {};
    for (line) |char| {
        switch (char) {
            '\r' => continue,
            '-' => {
                std.debug.assert(currently_parsing == .RangeStart);
                currently_parsing = .RangeEnd;
            },
            ',' => {
                input_line.range1.start = try std.fmt.parseInt(u32, range_start[0..range_start_index], 10);
                input_line.range1.end = try std.fmt.parseInt(u32, range_end[0..range_end_index], 10);

                range_start_index = 0;
                range_start = std.mem.zeroes([10]u8);
                range_end_index = 0;
                range_end = std.mem.zeroes([10]u8);
                currently_parsing = .RangeStart;
            },
            '0'...'9' => {
                if (currently_parsing == .RangeStart) {
                    range_start[range_start_index] = char;
                    range_start_index += 1;
                }
                else {
                    range_end[range_end_index] = char;
                    range_end_index += 1;
                }
            },
            else => unreachable
        }

    }
    input_line.range2.start = try std.fmt.parseInt(u32, range_start[0..range_start_index], 10);
    input_line.range2.end = try std.fmt.parseInt(u32, range_end[0..range_end_index], 10);
    // std.debug.print("input line: {d}-{d}, {d}-{d}\n", .{input_line.range1.start, input_line.range1.end, input_line.range2.start, input_line.range2.end});
    return input_line;
}

fn does_range_cover_range(range1: Range, range2: Range) bool {
    return range1.start <= range2.start and range1.end >= range2.end;
}

pub fn run() !void {
    var file = try std.fs.cwd().openFile("input/4/input.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    
    var redundant_section_assignments: u32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line[0] == '\n') continue;
        var input = try parse_input_line(line);
        if (does_range_cover_range(input.range1, input.range2) or does_range_cover_range(input.range2, input.range1)) {
            redundant_section_assignments += 1;
        }
    }
    std.debug.print("4a -> {d}\n", .{redundant_section_assignments});
}
