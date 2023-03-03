const std = @import("std");

const ThisFile = @This();
const Input = enum { example, example2, input };
const Part = enum { a, b };
const AocDay = struct {
    day: u8,
    part: Part
};

const in = Input.input;
const debug = false;
const megabytes = 2;

fn line_iterator(name: []const u8, comptime function: fn(line:[]u8, line_number: usize) anyerror!void) !void {
    var file = try std.fs.cwd().openFile(name, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var current_line_buffer: [1024]u8 = undefined;
    var line_number: usize = 0;
    while (try buf_reader.reader().readUntilDelimiterOrEof(&current_line_buffer, '\n')) |line| {
        // git for windows INSISTS on modifying the files so that they use windows line terminations `crlf`
        if (line[line.len-1] == '\r') unreachable;
        try function(line, line_number);
    }
}

var hx: i32 = 0;
var hy: i32 = 0;

var tx: [9]i32 = [_]i32{0} ** 9;
var ty: [9]i32 = [_]i32{0} ** 9;

const Position = struct {
    x: i32, y: i32
};

var positions: std.AutoHashMap(Position, void) = undefined;

pub fn run() !void {
    
    const aoc: AocDay = comptime blk: {

        // https://github.com/Hejsil/mecha f039efe
        const mecha = @import("mecha");

        const parser_for_day_number_part =

            mecha.combine(.{
                // 1. discard the string "day"
                mecha.discard(mecha.string("day")),
                // 2. map the rest to a struct AocDay { u8, enum Part {a, b} }
                mecha.map(
                    mecha.toStruct(AocDay),
                    mecha.combine(.{
                        // 1. first comes a number
                        mecha.int(u8, .{}),
                        // 1. then a character 'a' or 'b' which map directly to the enum Part { a, b }
                        mecha.enumeration(Part)
                    })
                )
            });

        // Example: "day9a"
        const file_name = @typeName(ThisFile);
        
        // 1 megabyte of stack memory
        var mem: [1000*1000]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&mem);
        
        const parse_result = try parser_for_day_number_part(fba.allocator(), file_name);
        break :blk parse_result.value;
    };
    
    var input_file = comptime std.fmt.comptimePrint("input/{d}/{s}.txt", .{aoc.day, @tagName(in)});
    
    var mem: [megabytes*1000*1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&mem);
    positions = std.AutoHashMap(Position, void).init(fba.allocator());
    
    try line_iterator(input_file, struct {

        fn callback(line:[]u8, _: usize) !void {

            if (line.len == 0) return; // ignore empty lines
            const direction = line[0];
            const times = try std.fmt.parseInt(usize, line[2..], 10);
            var count: usize = 0;
            while (count < times) : (count += 1) {
                
                switch (direction) {
                    'U' => hy += 1,
                    'D' => hy -= 1,
                    'L' => hx -= 1,
                    'R' => hx += 1,
                    else => unreachable
                }

                for (tx, 0..) |_, i| {
                
                    var towardsx: *i32 = undefined;
                    var towardsy: *i32 = undefined;
                    if (i == 0) {
                        towardsx = &hx;
                        towardsy = &hy;
                    }
                    else {
                        towardsx = &tx[i-1];
                        towardsy = &ty[i-1];
                    }

                    const origx: *i32 = &tx[i];
                    const origy: *i32 = &ty[i];

                    const dx = towardsx.* - origx.*;
                    const dy = towardsy.* - origy.*;

                    if (dx > 1) {
                        origx.* += 1;
                    
                        if (dy > 0) {
                            origy.* += 1;
                        }
                        else if (dy < 0) {
                            origy.* -= 1;
                        }
                    }
                    else if (dx < -1) {
                        origx.* -= 1;

                        if (dy > 0) {
                            origy.* += 1;
                        }
                        else if (dy < 0) {
                            origy.* -= 1;
                        }
                    }


                    else if (dy > 1) {
                        origy.* += 1;

                        if (dx > 0) {
                            origx.* += 1;
                        }
                        else if (dx < 0) {
                            origx.* -= 1;
                        }
                    }
                    else if (dy < -1) {
                        origy.* -= 1;

                        if (dx > 0) {
                            origx.* += 1;
                        }
                        else if (dx < 0) {
                            origx.* -= 1;
                        }
                    }

                }
                _ = try positions.put(.{ .x = tx[8], .y = ty[8] }, {});
            }

            if (debug and in == .example2) {

                // screen "background"
                const screen_bg = 
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\...........s..............
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\..........................
                    \\
                ;

                const columns: usize = blk: {
                    for (screen_bg, 0..) |c, i| if (c == '\n') break :blk i+1;
                    unreachable;
                };
                const rows = @divExact(screen_bg.len, columns);
                _ = rows;

                // offsets since 's' is not at 0, 0
                const offsetx: i32 = 12-1;
                const offsety: i32 = 7-2;
                
                var screen: [screen_bg.len]u8 = undefined;

                // clear the screen
                std.mem.copy(u8, &screen, screen_bg);
                // draw the head
                screen[@intCast(usize, (hx + offsetx) + @intCast(i32, columns) * (hy+offsety))] = 'H';
                // draw the tail
                for (tx, 0..) |_, i| screen[@intCast(usize, (tx[i]+offsetx) + @intCast(i32, columns) * (ty[i]+offsety))] = '1' + @intCast(u8, i);
                // render
                std.debug.print("{s}\n\n", .{screen});
            }
        }

    }.callback);

    var it = positions.keyIterator();
    if (debug) while (it.next()) |next| {
        std.debug.print("{}, {}\n", .{next.x, next.y});
    };

    const solution: usize = positions.count();
    std.debug.print("Advent Of Code 2022, day {d}, part {s}, input: {s}, solution: {d}\n", .{aoc.day, @tagName(aoc.part), @tagName(in), solution});
}
