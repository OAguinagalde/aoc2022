const std = @import("std");

// other    me
// a        x   rock
// b        y   paper
// c        z   scissors

// Score =
//     1 points for selecting rock
//     2 points for selecting paper
//     3 points for selecting scissors
// PLUS
//     0 points for losing
//     3 points for draw
//     6 points for winning

const move = enum {
    rock,
    paper,
    scissors,
};

fn parse_move(char: u8) move {
    return switch (char) {
        'A' => move.rock,
        'B' => move.paper,
        'C' => move.scissors,
        'X' => move.rock,
        'Y' => move.paper,
        'Z' => move.scissors,
        else => unreachable
    };
}

fn round_score(my_move: move, oponent_move: move) u32 {
    return switch (my_move) {
        .rock => 1 + switch(oponent_move) {
            .rock => @as(u32, 3),
            .paper => 0,
            .scissors => 6,
        },
        .paper => 2 + switch(oponent_move) {
            .rock => @as(u32, 6),
            .paper => 3,
            .scissors => 0,
        },
        .scissors => 3 + switch(oponent_move) {
            .rock => @as(u32, 0),
            .paper => 6,
            .scissors => 3,
        },
    };
}

pub fn run() !void {
    var file = try std.fs.cwd().openFile("input/2/input.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var reader = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    
    var score: u32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |slice| {
        switch (slice[0]) {
            '\n' => continue,
            else => {
                score += round_score(parse_move(slice[2]), parse_move(slice[0]));
            }
        }
    }
    std.debug.print("2a -> {d}\n", .{score});
}
