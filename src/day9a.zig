const std = @import("std");

const ThisFile = @This();
const Input = enum { example, input };
const Part = enum { a, b };
const AocDay = struct {
    day: u8,
    part: Part
};

const in = Input.input;
const debug = false;
const megabytes = 2;

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
                    AocDay,
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

    var mem: [megabytes*1000*1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&mem);
    
    var input_file = comptime std.fmt.comptimePrint("input/{d}/{s}.txt", .{aoc.day, @tagName(in)});
    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var hx: i32 = 0;
    var hy: i32 = 0;

    var tx: i32 = 0;
    var ty: i32 = 0;

    const Position = struct {
        x: i32, y: i32
    };
    
    var positions = std.AutoHashMap(Position, void).init(fba.allocator());
    
    var buf_reader = std.io.bufferedReader(file.reader());
    var current_line_buffer: [1024]u8 = undefined;
    var line_number: usize = 0;
    while (try buf_reader.reader().readUntilDelimiterOrEof(&current_line_buffer, '\n')) |line| {
        // git for windows INSISTS on modifying the files so that they use windows line terminations `crlf`
        if (line[line.len-1] == '\r') unreachable;
        // ignore empty lines
        if (line.len == 0) continue;

        const direction = line[0];
        const times = try std.fmt.parseInt(usize, line[2..], 10);
        var count: usize = 0;
        while (count < times) : (count += 1) {
            switch (direction) {
                'U' => {
                    hy += 1;
                    
                    const dy = try std.math.absInt(hy - ty);
                    
                    if (dy > 1) {
                        ty += 1;
                        
                        const dx = hx - tx;
                        if (dx > 0) tx += 1
                        else if (dx < 0) tx -= 1;
                    }

                },
                'D' => {
                    hy -= 1;

                    const dy = try std.math.absInt(hy - ty);
                    
                    if (dy > 1) {
                        ty -= 1;
                        
                        const dx = hx - tx;
                        if (dx > 0) tx += 1
                        else if (dx < 0) tx -= 1;
                    }
                
                },
                'L' => {
                    hx -= 1;

                    const dx = try std.math.absInt(hx - tx);

                    if (dx > 1) {
                        tx -= 1;

                        const dy = hy - ty;
                        if (dy > 0) ty += 1
                        else if (dy < 0) ty -= 1;
                    }
                
                },
                'R' => {
                    hx += 1;

                    const dx = try std.math.absInt(hx - tx);

                    if (dx > 1) {
                        tx += 1;

                        const dy = hy - ty;
                        if (dy > 0) ty += 1
                        else if (dy < 0) ty -= 1;
                    }
                },
                else => unreachable
            }
            if (debug) std.debug.print("{}, {}\n", .{tx, ty});
            _ = try positions.put(.{ .x = tx, .y = ty }, {});
        }


        line_number += 1;
    }

    const solution: usize = positions.count();
    std.debug.print("Advent Of Code 2022, day {d}, part {s}, input: {s}, solution: {d}\n", .{aoc.day, @tagName(aoc.part), @tagName(in), solution});
}
