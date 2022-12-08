const std = @import("std");

const Mode = enum { ParseInitialState, ParseInstructions };

pub fn run() !void {
    var file = try std.fs.cwd().openFile("input/6/example.txt", .{});
    errdefer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();

    var bunch_of_stack_memory: [1024*2]u8 = undefined;
    var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(&bunch_of_stack_memory);

    var results = std.ArrayList(usize).init(fixed_buffer_allocator.allocator());
    var character_set = std.AutoHashMap(u8, usize).init(fixed_buffer_allocator.allocator());
    try character_set.ensureTotalCapacity(4);
    var file_read_buffer: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&file_read_buffer, '\n')) |line| { // line doesnt contain the delimiter '\n'
        if (line.len == 0) continue; // ignore empty lines
        
        const input = line;
        
        character_set.clearRetainingCapacity();
        
        var index: usize = 0;
        while (index < input.len): (index += 1) {
            
            if (index >= 4) {
                // reduce character counter or remove character if last one
                var entry_to_remove = character_set.getEntry(input[index-4]).?;
                if (entry_to_remove.value_ptr.* > 1) {
                    entry_to_remove.value_ptr.* -= 1;
                }
                else {
                    _ = character_set.remove(input[index-4]);
                }
            }

            // increment character counter or add if new character
            var entry_to_add = try character_set.getOrPut(input[index]);
            if (entry_to_add.found_existing) {
                entry_to_add.value_ptr.* += 1;
            }
            else {
                entry_to_add.value_ptr.* = 1;
            }
            
            if (character_set.count() == 4) {
                try results.append(index + 1);
                break;
            }
        }
    }

    for (results.items) |result| {
        std.debug.print("result is: {}\n", .{result});
    }

    std.debug.print("6a -> {d}\n", .{0});
}
