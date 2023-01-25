const std = @import("std");

const ThisFile = @This();
const Input = enum { example, example2, input };
const Part = enum { a, b };
const AocDay = struct {
    day: u8,
    part: Part
};

const in = Input.example;
const debug = true;
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
    
    var input_file = comptime std.fmt.comptimePrint("input/{d}/{s}.txt", .{aoc.day, @tagName(in)});
    
    var mem: [megabytes*1000*1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&mem);
    _ = fba;
    
    try line_iterator(input_file, struct {

        fn callback(line:[]u8, _: usize) !void {
            if (line.len == 0) return; // ignore empty lines
        }

    }.callback);

    const solution: i32 = 0;
    std.debug.print("Advent Of Code 2022, day {d}, part {s}, input: {s}, solution:\n\n{d}\n", .{aoc.day, @tagName(aoc.part), @tagName(in), solution});
}

test {
    const example =
        \\Monkey 0:
        \\  Starting items: 79, 98
        \\  Operation: new = old * 19
        \\  Test: divisible by 23
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 3
        \\
        \\Monkey 1:
        \\  Starting items: 54, 65, 75, 74
        \\  Operation: new = old + 6
        \\  Test: divisible by 19
        \\    If true: throw to monkey 2
        \\    If false: throw to monkey 0
        \\
        \\Monkey 2:
        \\  Starting items: 79, 60, 97
        \\  Operation: new = old * old
        \\  Test: divisible by 13
        \\    If true: throw to monkey 1
        \\    If false: throw to monkey 3
        \\
        \\Monkey 3:
        \\  Starting items: 74
        \\  Operation: new = old + 3
        \\  Test: divisible by 17
        \\    If true: throw to monkey 0
        \\    If false: throw to monkey 1
    ;

    // https://github.com/Hejsil/mecha f039efe
    const mecha = @import("mecha");

    const Item = struct {
        worry: i32
    };
    const Operation = struct {
        const Type = enum {
            @"+",
            @"*"
        };
        type: Type
    };
    const Monkey = struct {
        id: usize,
        items: []Item,
        operation: Operation,
        division_test_value: i32,
        test_pass_monkey_id: i32,
        test_fail_monkey_id: i32,
    };
    
    const helper = struct {
        
        const comma_separated_items =
            mecha.oneOf(.{                                                       
                mecha.combine(.{
                    mecha.map(Item, mecha.toStruct(Item), mecha.int(i32, .{})),
                    mecha.discard(mecha.string(", ")),
                    mecha.ref(more_comma_separated_items),
                }),
                mecha.map(Item, mecha.toStruct(Item), mecha.int(i32, .{}))
            });

        fn more_comma_separated_items() mecha.Parser(Item){
            return comma_separated_items;
        }

    };

    const parser =
        mecha.many(
            mecha.map(Monkey, mecha.toStruct(Monkey), mecha.combine(.{
                mecha.discard(mecha.string("Monkey ")),
                mecha.int(usize, .{}),
                mecha.discard(mecha.string(":")),
                mecha.discard(mecha.ascii.space),
                mecha.discard(mecha.string("Starting items: ")),
                helper.comma_separated_items,
                mecha.discard(mecha.string("Operation: new = old ")),
                mecha.map(Operation, mecha.toStruct(Operation), mecha.combine(.{
                    mecha.enumeration(Operation.Type),
                    mecha.discard(mecha.ascii.space),
                    mecha.discard(mecha.oneOf(.{
                        mecha.string("old"),
                        mecha.int(i32, .{})
                    }))
                })),
                mecha.discard(mecha.ascii.space),
                mecha.discard(mecha.string("Test: divisible by ")),
                mecha.int(i32, .{}),
                mecha.discard(mecha.ascii.space),
                mecha.discard(mecha.string("If true: throw to monkey ")),
                mecha.int(i32, .{}),
                mecha.discard(mecha.ascii.space),
                mecha.discard(mecha.string("If false: throw to monkey ")),
                mecha.int(i32, .{}),
                mecha.discard(mecha.opt(mecha.ascii.space)),
            }))
        , .{});

    var mem: [1*1000*1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&mem);
    const result = try parser(fba.allocator(), example);
    const monkeys: []Monkey = result.value;
    for (monkeys) |monkey| {
        std.debug.print("Monkey {d}\n", .{monkey.id});
        std.debug.print("division test {d}\n", .{monkey.division_test_value});
        std.debug.print("operation {s}\n", .{@tagName(monkey.operation.type)});
    }
}
