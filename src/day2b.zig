const std = @import("std");

const move = enum {
    rock,
    paper,
    scissors,
};

const outcome = enum {
    win,
    draw,
    lose,
};

fn parse_outcome(char: u8) outcome {
    return switch (char) {
        'X' => outcome.lose,
        'Y' => outcome.draw,
        'Z' => outcome.win,
        else => unreachable
    };
}

fn parse_move(char: u8) move {
    return switch (char) {
        'A' => move.rock,
        'B' => move.paper,
        'C' => move.scissors,
        else => unreachable
    };
}

fn round_score(my_move: move, _outcome: outcome) u32 {
    return switch (my_move) {
        .rock => @as(u32, 1),
        .paper => 2,
        .scissors => 3
    } + switch(_outcome) {
        .draw => @as(u32, 3),
        .lose => 0,
        .win => 6,
    };
}

fn calculate_move(enemy_move: move, desired_outcome: outcome) move {
    return switch (enemy_move) {
        .rock => switch(desired_outcome) {
            .win => @as(move, .paper),
            .lose => .scissors,
            .draw => .rock,
        },
        .paper => switch(desired_outcome) {
            .win => @as(move, .scissors),
            .lose => .rock,
            .draw => .paper,
        },
        .scissors => switch(desired_outcome) {
            .win => @as(move, .rock),
            .lose => .paper,
            .draw => .scissors,
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
                var oponent_move = parse_move(slice[0]);
                var desired_outcome = parse_outcome(slice[2]);
                var my_move = calculate_move(oponent_move, desired_outcome);
                score += round_score(my_move, desired_outcome);
            }
        }
    }
    std.debug.print("2b -> {d}\n", .{score});
}
