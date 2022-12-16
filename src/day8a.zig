const std = @import("std");

const Input = enum { Example, Real };
const Part = enum { a, b };

const day: usize = 8;
const part = Part.a;
const mode = Input.Real;
const debug = false;

const TreeSet = std.AutoHashMap(usize, void);

const Tree = struct {
    index: usize,
    height: u8,
};

fn visible_from_sides(tree_line:[]Tree, visible_trees: *TreeSet, allocator: std.mem.Allocator) !void {

    // An stack wich contains the trees that are viewable from the right, where the top is the smallest viewable tree
    var viewable_from_right = std.ArrayList(Tree).init(allocator);
    defer viewable_from_right.clearAndFree();
    var viewable_from_left = std.ArrayList(Tree).init(allocator);
    defer viewable_from_left.clearAndFree();

    for (tree_line) |tree| {

        if (viewable_from_left.items.len == 0) {
            try viewable_from_left.append(tree);
        }
        else {
            // The tallest tree that is viewable from the left (so far)
            const tallest: Tree = viewable_from_left.items[viewable_from_left.items.len-1];
            if (tree.height > tallest.height) try viewable_from_left.append(tree);
        }

        var i: usize = 1;
        while (if (viewable_from_right.items.len > i-1) viewable_from_right.items[viewable_from_right.items.len-i] else null) |smallest| {
            // the smallest tree viewable from the right (so far)
            if (smallest.height <= tree.height) _ = viewable_from_right.pop()
            else i += 1;
        }
        try viewable_from_right.append(tree);
    }

    for (viewable_from_right.items) |tree| {
        try visible_trees.put(tree.index, {});
    }

    for (viewable_from_left.items) |tree| {
        try visible_trees.put(tree.index, {});
    }
}

fn visible(columns: []std.ArrayList(Tree), rows: []std.ArrayList(Tree), allocator: std.mem.Allocator) !usize {

    var visible_trees = TreeSet.init(allocator);

    for (columns) |tree_array| {
        try visible_from_sides(tree_array.items, &visible_trees, allocator);
    }

    for (rows) |tree_array| {
        try visible_from_sides(tree_array.items, &visible_trees, allocator);

        if (debug) {
            var buf: [200]u8 = undefined;
            for (tree_array.items) |tree, i| {
                _ = try std.fmt.bufPrint(buf[i..], "{c}", .{if (visible_trees.contains(tree.index)) tree.height + '0' else '|' });
            }
            std.debug.print("{s}\n", .{buf[0..tree_array.items.len]});
        }
    }
    
    return visible_trees.count();
}

pub fn run() !void {
    
    var input_file = comptime std.fmt.comptimePrint("input/{d}/{s}.txt", .{day, switch (mode) { .Example => "example", .Real => "input" }});
    
    var bunch_of_stack_memory: [1024*1000]u8 = undefined;
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
