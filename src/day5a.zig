const std = @import("std");

const Mode = enum { ParseInitialState, ParseInstructions };

pub fn run() !void {
    var file = try std.fs.cwd().openFile("input/5/input.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    // This is the buffer that will hold the line of input
    var buf: [1024]u8 = undefined;

    // This must be enough to hold the evolving `std.ArrayList(std.ArrayList(u8))`
    // that represents the stacks of this problem
    // 2KB seems to be enough for the input
    var bunch_of_stack_memory: [1024*2]u8 = undefined;
    var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(&bunch_of_stack_memory);
    const amazing_allocator = fixed_buffer_allocator.allocator();

    // LITERAL QUESTION I JUST ASKED ON ZIG DISCORD :
    // > 16:37 Oscar: I have only found `std.atomic.Stack`, but that one doesn't handle allocation.
    // > Is there a `Stack` which will accept an `Allocator` on `init`, and will then
    // > handle memory while keeping the items contiguous?
    // > 16:38 Oscar: Oh wait, I literally described an `std.ArrayList` didn't I?
    var stacks = std.ArrayList(std.ArrayList(u8)).init(amazing_allocator);
    defer stacks.deinit();
    var mode: Mode = .ParseInitialState;
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
                if (stacks.items.len == 0) {
                    // The `line.len + 1` is because each stack is:
                    // 3 characters '[', '?' and ']', followed by an space ' ' (4 characters in total).
                    // But the last stack doesn't have a trailing space! (hence, (len + 1) / 4)
                    const stack_count = @divExact(line.len + 1, 4);

                    // allocate enough stacks for the problem
                    var i:  usize = 0;
                    while (i < stack_count) : (i += 1) {
                        var stack = try stacks.addOne();
                        stack.* = std.ArrayList(u8).init(amazing_allocator);
                    }
                }

                // push the items in the current line into the stacks.
                // Example line: '    [D]    '
                for (stacks.items, 0..) |*stack, i| {
                    const item = line[(i * 4) + 1];
                    if (item == ' ') continue;
                    try stack.insert(0, item);
                }

            },
            .ParseInstructions => {

                const skip_move = "move ";
                const skip_from = " from ";
                const skip_to = " to ";
                
                const index_from = std.ascii.indexOfIgnoreCasePos(line, skip_move.len, skip_from).?;
                const index_to = std.ascii.indexOfIgnoreCasePos(line, index_from + skip_from.len, skip_to).?;

                const repeat_number_string = line[skip_move.len .. index_from];
                const stack_origin_string = line[index_from + skip_from.len .. index_to];
                const stack_target_string = line[index_to + skip_to.len .. line.len];

                const repeat_number = try std.fmt.parseInt(usize, repeat_number_string, 10);
                // I'm doing -1 because the indexes given start from 1 but I use 0-based indexes
                const stack_origin = try std.fmt.parseInt(usize, stack_origin_string, 10) - 1;
                const stack_target = try std.fmt.parseInt(usize, stack_target_string, 10) - 1;
               
                if (false) std.debug.print("moving an item from stack {d}, to stack {d}, a total of {d} times\n", .{stack_origin, stack_target, repeat_number});

                const o = &stacks.items[stack_origin];
                const t = &stacks.items[stack_target];
                
                var i: usize = 0;
                while (i < repeat_number) : (i += 1) {
                    try t.append(o.pop());
                }
            }
        }

        const debug_print_status_of_stacks = false;
        if (debug_print_status_of_stacks) for (stacks.items, 0..) |stack, i| {
            std.debug.print("{d} : [", .{i+1});
            for (stack.items) |item| {
                std.debug.print("{c}, ", .{item});
            }
            std.debug.print("]\n", .{});
        };
    }

    // Now the stacks have the final state, so calculate the points
    var message = std.mem.zeroes([1024] u8);
    for (stacks.items, 0..) |stack, i| {
        if (stack.items.len == 0) continue;
        message[i] = stack.items[stack.items.len - 1];
    }

    std.debug.print("5a -> {s}\n", .{message[0..stacks.items.len]});
}
