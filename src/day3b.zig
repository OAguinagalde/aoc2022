const std = @import("std");

const Rucksack = struct {
    
    const total_item_types: u8 = ('z' - 'a' + 1) + ('Z' - 'A' + 1);
    const item_counter = [total_item_types]u8;
    
    items_count: item_counter = std.mem.zeroes(item_counter),
    
    fn add_next_item(self: *Rucksack, item: u8) void {
        self.items_count[item] += 1;
    }

    fn new() Rucksack {
        return Rucksack {};
    }
};

fn find_item_in_common(a: Rucksack, b: Rucksack, c: Rucksack) u8 {
    for(a.items_count) |count, item_type| {
        if (count != 0 and b.items_count[item_type] != 0 and c.items_count[item_type] != 0) {
            return @intCast(u8, item_type);
        }
    }
    return unreachable;
}

/// converts characters between 'a'...'z' to a number between 0...('z'-'a')
/// and characters between 'A'...'Z' to a number from ('z'-'a'+1)...(('z' - 'a' + 1) + ('Z' - 'A'))
/// Example: 
///
///     try std.testing.expect('z'-'a' == 25);
///     try std.testing.expect(convert('a') == 0);
///     try std.testing.expect(convert('z') == 25);
///     try std.testing.expect(convert('A') == 26);
///     try std.testing.expect(convert('Z') == 51);
///
fn convert(orig: u8) u8 {
    return switch (orig) {
        'a'...'z' => orig - 'a',
        'A'...'Z' => orig - 'A' + ('z' - 'a' + 1),
        else => unreachable
    };
}

/// given a u8 that has been previously converted with `fn convert(...)`, converts it back to its original value
fn convert_back(converted: u8) u8 {
    return switch (converted) {
        0...('z' - 'a') => converted + 'a',
        ('z' - 'a' + 1)...(('z' - 'a' + 1) + ('Z' - 'A')) => converted + 'A' - ('z' - 'a' + 1),
        else => unreachable
    };
}

test "convert and convert_back" {
    {
        var item: u8 = 'a';
        var converted = convert(item);
        try std.testing.expect(converted == 0);
        var converted_back = convert_back(converted);
        try std.testing.expect(converted_back == item);
    }
    {
        var item: u8 = 'z';
        var converted = convert(item);
        try std.testing.expect(converted == ('z'-'a'));
        var converted_back = convert_back(converted);
        try std.testing.expect(converted_back == item);
    }
    {
        var item: u8 = 'A';
        var converted = convert(item);
        try std.testing.expect(converted == ('z'-'a'+1));
        var converted_back = convert_back(converted);
        try std.testing.expect(converted_back == item);
    }
    {
        var item: u8 = 'Z';
        var converted = convert(item);
        try std.testing.expect(converted == ('z'-'a'+1) + ('Z'-'A'));
        var converted_back = convert_back(converted);
        try std.testing.expect(converted_back == item);
    }
}

pub fn run() !void {
    var file = try std.fs.cwd().openFile("input/3/input.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    
    var priorities_sum: u32 = 0;
    var elf_index: u32 = 0;
    var rucksack_a = Rucksack.new();
    var rucksack_b = Rucksack.new();
    var rucksack_c = Rucksack.new();
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |rucksack_data| {
        switch (rucksack_data[0]) {
            '\n' => continue,
            else => {
                var rucksack = Rucksack.new(rucksack_data.len);
                for (rucksack_data) |item| {
                    switch (item) {
                        '\r' => continue,
                        else => rucksack.add_next_item(convert(item))
                    }
                }
                if (elf_index % 3 == 0) {
                    if (elf_index != 0) {
                        // TODO find the item all 3 have in common
                        var item_in_common_converted = find_item_in_common(rucksack_a, rucksack_b, rucksack_c);
                    }
                    // TODO start a new group
                }
                elf_index += 1;
            }
        }
    }

    std.debug.print("3a -> {d}\n", .{priorities_sum});
}
