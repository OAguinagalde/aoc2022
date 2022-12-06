const std = @import("std");

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

const Mode = enum { ParseInitialState, ParseInstructions };

pub fn run() !void {
    var file = try std.fs.cwd().openFile("input/5/example.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    
    var heap_memory_lol: [1024]u8 = undefined;
    var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(&heap_memory_lol);
    const amazing_allocator = fixed_buffer_allocator.allocator();

    // LITERAL QUESTION I JUST ASKED ON ZIG DISCORD :
    // > 16:37 Oscar: I have only found `std.atomic.Stack`, but that one doesn't handle allocation.
    // > Is there a `Stack` which will accept an `Allocator` on `init`, and will then
    // > handle memory while keeping the items contiguous?
    // > 16:38 Oscar: Oh wait, I literally described an `std.ArrayList` didn't I?
    var stacks = std.ArrayList(std.ArrayList(u8)).init(amazing_allocator);
    var mode = .ParseInitialState;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        
        if (line.len == 0) {
            if (mode == .ParseInitialState) {
                mode = .ParseInstructions;
            }
            else {
                // This is the end of the program, no need to do anything
            }
            continue;
        }

        switch (mode) {
            .ParseInitialState => {

                // This is the last line before the emtpy line which we dont care about
                if (line[1] == '1') continue;
                
                // If len is 0 it means that it has not been initialized
                // meaning we have have to initialize it now
                if (stacks.c == 0) {
                    // The `line.len + 1` is because each stack is:
                    // 3 characters '[', '?' and ']', followed by an space ' ' (4 characters in total).
                    // But the last stack doesn't have a trailing space! (hence, (len + 1) / 4)
                    const stack_count = @divExact(line.len + 1, 4);

                    // init the stacks
                    var i:  usize = 0;
                    while (i < stack_count) : (i += 1) {
                        var stack = try stacks.addOne();
                        stack.*.init(amazing_allocator);
                    }
                }

                // push the items into the stacks, and when they have been loaded, reverse the stacks, since we loadeed them in reverse
                const stack_count = stacks.items.len;
                var i:  usize = 0;
                while (i < stack_count) : (i += 1) {
                    const char_index = (i * 4) + 1;
                    const item_in_stack = line[char_index];
                    if (item_in_stack == ' ') continue;

                    var stack: *std.ArrayList(u8) = stacks.items[i];
                    // This is not super performant, its O(N). I could instead just do `addOne` and when finished adding everything
                    // reverse them, but it's not a huge input anyway so whatever.
                    try stack.*.insert(0, item_in_stack);
                }

            },
            .ParseInstructions => {
                // Parse the movement type and the times that the movement is going to happen
                // and execute those one by one.
                // TODO
            },
            else => unreachable
        }
    }
    // Now the stacks have the final state, so calculate the points
    // TODO
    
    std.debug.print("5a -> {d}\n", .{0});
}
