const std = @import("std");

const Mode = enum { ParseInitialState, ParseInstructions };

pub fn run() !void {
    var file = try std.fs.cwd().openFile("input/6/example.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    // Allocator used if necessary during the problem
    var bunch_of_stack_memory: [1024*2]u8 = undefined;
    var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(&bunch_of_stack_memory);
    const allocator = fixed_buffer_allocator.allocator();
    _ = allocator;

    var file_read_buffer: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&file_read_buffer, '\n')) |line| { // line doesnt contain the delimiter '\n'
        if (line.len == 0) continue; // ignore empty lines
        const input = line;
        _ = input;
    }

    std.debug.print("6a -> {d}\n", .{0});
}
