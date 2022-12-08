const std = @import("std");

const Input = enum { Example, Real };
const Part = enum { A, B };

pub fn run() !void {
    
    const day: usize = 7;
    const part = Part.A;
    const mode = Input.Example;

    // TODO I get error `error: unable to infer array size` but this is supposed to be comptime so... how come?
    var input_file: [_]u8 = comptime {
        const file_name = switch (mode) {
            .Example => "example", .Real => "input"
        };
        // TODO is there a better way of doing this?
        var input_file_name: [1024]u8 = undefined;
        const length = std.fmt.bufPrint(input_file_name, "input/{d}/{s}.txt", .{day, file_name});
        return input_file_name[0..length];
    };
    
    var bunch_of_stack_memory: [1024*2]u8 = undefined;
    var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(&bunch_of_stack_memory);
    _ = fixed_buffer_allocator;
    
    var file = try std.fs.cwd().openFile(input_file, .{});
    
    // TODO how do I handle the file close in both "normal execution" and "error execution"?
    defer file.close();
    errdefer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var file_read_buffer: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&file_read_buffer, '\n')) |line| { // line doesnt contain the delimiter '\n'
        if (line.len == 0) continue; // ignore empty lines
        const input = line;
        _ = input;
    }

    std.debug.print("{}{} -> {}\n", .{day, part, 0});
}
