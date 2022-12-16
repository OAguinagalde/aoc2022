const std = @import("std");

const Input = enum { Example, Real };
const Part = enum { a, b };

const day: usize = 8;
const part = Part.b;
const mode = Input.Real;
const debug = false;
const megabytes = 2;

const TreeSet = std.AutoHashMap(usize, usize);

const Tree = struct {
    index: usize,
    height: u8,
};

fn calculate_scenic_score_for_line(tree_line:[]Tree, visible_trees: *TreeSet) !void {

    const total = tree_line.len;
    for (tree_line) |tree, i| {

        const left_count: usize = switch (i) {
            0 => 0,
            1 => 1,
            else => blk: {
                var count: usize = 0;
                var index: usize = 1;

                while (i >= index) : (index+=1) {
                    var h = tree_line[i-index].height;
                    if (h < tree.height) { count += 1; }
                    else { count += 1; break; }
                }

                break :blk count;
            }
        };

        const right_count: usize = if (i == total-1) 0
        else if (i == total-2) 1
        else blk: {
            var count: usize = 0;
            var index: usize = 1;

            while (i+index < total) : (index+=1) {
                var h = tree_line[i+index].height;
                if (h < tree.height) { count += 1; }
                else { count += 1; break; }
            }

            break :blk count;
        };
        
        var entry = try visible_trees.getOrPut(tree.index);
        if (entry.found_existing) {
            if (debug) std.debug.print("tree {d:->6} (existing){d:->6} * {d:->6} * {d:->6} = {d:->6}\n", .{tree.index, entry.value_ptr.*, left_count, right_count, (entry.value_ptr.* * left_count * right_count)});
            entry.value_ptr.* = (entry.value_ptr.*) * (right_count * left_count);
        }
        else {
            if (debug) std.debug.print("tree {d:->6} {d:->6} * {d:->6} = {d:->6}\n", .{tree.index, left_count, right_count, (left_count * right_count)});
            entry.value_ptr.* = (right_count * left_count);
        }

    }
}

fn visible(columns: []std.ArrayList(Tree), rows: []std.ArrayList(Tree), allocator: std.mem.Allocator) !usize {

    var visible_trees = TreeSet.init(allocator);

    for (rows) |tree_array| {
        try calculate_scenic_score_for_line(tree_array.items, &visible_trees);
    }

    for (columns) |tree_array| {
        try calculate_scenic_score_for_line(tree_array.items, &visible_trees);

    }
    
    if (debug) {
        for (rows) |tree_array| {
            var index: usize = 0;
            var buf: [1024]u8 = undefined;
            for (tree_array.items) |tree| {
                const printed = try std.fmt.bufPrint(buf[index..], "{d:->6} ", .{visible_trees.get(tree.index).?});
                index += printed.len;
            }
            std.debug.print("{s}\n", .{buf[0..index]});
        }
    }
    
    var it = visible_trees.valueIterator();
    var max: usize = 0;
    while (it.next()) |score| {
        if (score.* > max) max = score.*;
    }
    return max;
}

pub fn run() !void {
    
    var input_file = comptime std.fmt.comptimePrint("input/{d}/{s}.txt", .{day, switch (mode) { .Example => "example", .Real => "input" }});
    
    var bunch_of_stack_memory: [megabytes*1000*1000]u8 = undefined;
    var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(&bunch_of_stack_memory);
    
    var columns = std.ArrayList(std.ArrayList(Tree)).init(fixed_buffer_allocator.allocator());
    var rows = std.ArrayList(std.ArrayList(Tree)).init(fixed_buffer_allocator.allocator());
    var dimensions: ?usize = null;
    var once = false;

    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var current_line_buffer: [1024]u8 = undefined;
    var line_number: usize = 0;
    while (try buf_reader.reader().readUntilDelimiterOrEof(&current_line_buffer, '\n')) |line| {
        if (line[line.len-1] == '\r') unreachable; // git for windows INSISTS on modifying the files so that they use windows line terminations `crlf`
        if (line.len == 0) continue; // ignore empty lines

        // initialize all colums once
        if (!once) {
            for (line) |_| try columns.append(std.ArrayList(Tree).init(fixed_buffer_allocator.allocator()));
            dimensions = line.len;
            once = true;
        }

        // initialize current row
        try rows.append(std.ArrayList(Tree).init(fixed_buffer_allocator.allocator()));

        // populate current row and partial column
        var row = &rows.items[rows.items.len-1];
        for (line) |height, column| {
            const tree = Tree { .height = height - '0', .index = (line_number * dimensions.?) + column };
            try columns.items[column].append(tree);
            try row.append(tree);
        }

        line_number += 1;
    }

    const solution: usize = try visible(columns.items, rows.items, fixed_buffer_allocator.allocator());
    std.debug.print("{d}{s} -> {}\n", .{day, @tagName(part), solution});
}
