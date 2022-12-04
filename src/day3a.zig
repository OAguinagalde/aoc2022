const std = @import("std");

const Rucksack = struct {
    
    const total_item_types: u8 = ('z' - 'a' + 1) + ('Z' - 'A' + 1);
    const item_counter = [total_item_types]u8;

    const RucksackError = error {
        NoItemOutOfPlaceFound
    };
    
    first_half: item_counter = std.mem.zeroes(item_counter),
    second_half: item_counter = std.mem.zeroes(item_counter),
    current_index: usize = 0,
    half_size: usize,
    
    fn add_next_item(self: *Rucksack, item: u8) void {
        if (self.current_index < self.half_size) {
            self.first_half[item] += 1;
        }
        else {
            self.second_half[item] += 1;
        }
        self.current_index += 1;
    }

    fn find_item_out_of_place(self: Rucksack) RucksackError!u8 {
        for(self.first_half) |count, item_type| {
            if (count != 0 and self.second_half[item_type] != 0) {
                return @intCast(u8, item_type);
            }
        }
        return RucksackError.NoItemOutOfPlaceFound;
    }

    fn new(size: usize) Rucksack {
        return Rucksack {
            .half_size = size/2
        };
    }
};

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
                const item_out_of_place_converted = try rucksack.find_item_out_of_place();
                // const item_out_of_place = convert_back(item_out_of_place_converted);
                // std.debug.print("item_out_of_place -> {c}\n", .{item_out_of_place});
                
                // It just so happens that my categorization of items is almost the same as the priority values of the items.
                // Gotta add 1 to get the values to get their priority.
                const item_priority = item_out_of_place_converted + 1;
                priorities_sum += item_priority;
            }
        }
    }

    std.debug.print("3a -> {d}\n", .{priorities_sum});
}
