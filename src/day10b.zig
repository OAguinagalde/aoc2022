const std = @import("std");

const ThisFile = @This();
const Input = enum { example, example2, input };
const Part = enum { a, b };
const AocDay = struct {
    day: u8,
    part: Part
};

const in = Input.input;
const debug = false;
const megabytes = 2;

fn line_iterator(name: []const u8, comptime function: fn(line:[]u8, line_number: usize) anyerror!void) !void {
    var file = try std.fs.cwd().openFile(name, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var current_line_buffer: [1024]u8 = undefined;
    var line_number: usize = 0;
    while (try buf_reader.reader().readUntilDelimiterOrEof(&current_line_buffer, '\n')) |line| {
        // git for windows INSISTS on modifying the files so that they use windows line terminations `crlf`
        if (line[line.len-1] == '\r') unreachable;
        try function(line, line_number);
    }
}

const CPU = struct {
    cycle: usize = 0,
    reg_x: i32 = 0,
    program: []Instruction,
    instruction_processing: ?Instruction,
    instruction_index: usize,
    instruction_finish_at: usize,

    const Instruction = struct {
        instruction: InstructionType,
        value: ?i32
    };

    const InstructionType = enum {
        noop,
        addx
    };

    fn start_next_instruction(self: *CPU) Instruction {
        const instruction = self.program[self.instruction_index];
        switch (instruction.instruction) {
            .noop => self.instruction_finish_at = self.cycle,
            .addx => self.instruction_finish_at = self.cycle + 1
        }
        self.instruction_processing = instruction;
        return instruction;
    }

    fn finish_current_instruction(self: *CPU) Instruction {
        const instruction = self.instruction_processing.?;
        switch (instruction.instruction) {
            .addx => self.reg_x += instruction.value.?,
            else => {}
        }
        self.instruction_index += 1;
        self.instruction_processing = null;
        return instruction;
    }

    fn load_program(program: []Instruction) CPU {
        return CPU {
            .cycle = 0,
            .reg_x = 1,
            .program = program,
            .instruction_index = 0,
            .instruction_finish_at = 0,
            .instruction_processing = null
        };
    }
    
    /// executes a cycle. returns the value of the reg_x during the cycle or null if the execution has finished.
    fn tick(self: *CPU) ?i32 {
        
        self.cycle += 1;

        var started: ?Instruction = null;
        var finished: ?Instruction = null;

        if (self.instruction_processing == null) {
            // There is no instruction loaded so load the next one
            started = self.start_next_instruction();
        }

        const reg_value = self.reg_x;

        if (self.instruction_processing) |_| {
            if (self.instruction_finish_at == self.cycle) {
                finished = self.finish_current_instruction();
            }
        }
        
        if (debug) std.debug.print("{d:->6} {d: >6} - {s: ^6} - {s: ^6}\n", .{
            self.cycle,
            reg_value,
            if (started) |inst| @tagName(inst.instruction) else "",
            if (finished) |inst| @tagName(inst.instruction) else ""
        });


        // If there is instructions left, the program is not finished
        return if (self.instruction_index < self.program.len) reg_value else null;
    }

};


var instructions: std.ArrayList(CPU.Instruction) = undefined;
var cpu: CPU = undefined;

pub fn run() !void {
    
    const aoc: AocDay = comptime blk: {

        // https://github.com/Hejsil/mecha f039efe
        const mecha = @import("mecha");

        const parser_for_day_number_part =

            mecha.combine(.{
                // 1. discard the string "day"
                mecha.discard(mecha.string("day")),
                // 2. map the rest to a struct AocDay { u8, enum Part {a, b} }
                mecha.map(
                    AocDay,
                    mecha.toStruct(AocDay),
                    mecha.combine(.{
                        // 1. first comes a number
                        mecha.int(u8, .{}),
                        // 1. then a character 'a' or 'b' which map directly to the enum Part { a, b }
                        mecha.enumeration(Part)
                    })
                )
            });

        // Example: "day9a"
        const file_name = @typeName(ThisFile);
        
        // 1 megabyte of stack memory
        var mem: [1000*1000]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&mem);
        
        const parse_result = try parser_for_day_number_part(fba.allocator(), file_name);
        break :blk parse_result.value;
    };
    
    var input_file = comptime std.fmt.comptimePrint("input/{d}/{s}.txt", .{aoc.day, @tagName(in)});
    
    var mem: [megabytes*1000*1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&mem);

    instructions = std.ArrayList(CPU.Instruction).init(fba.allocator());
    
    try line_iterator(input_file, struct {

        fn callback(line:[]u8, _: usize) !void {
            if (line.len == 0) return; // ignore empty lines
            var iterator = std.mem.tokenize(u8, line, " ");
            const instruction = iterator.next().?;
            if (instruction[0] == 'n') try instructions.append(.{ .instruction = .noop, .value = null })
            else if (instruction[0] == 'a') try instructions.append(.{ .instruction = .addx, .value = try std.fmt.parseInt(i32, iterator.next().?, 10) });
        }

    }.callback);


    const Screen = struct {

        // screen "background"
        const screen_initial_state = 
            \\........................................
            \\........................................
            \\........................................
            \\........................................
            \\........................................
            \\........................................
            \\
        ;

        const Pixel = struct {
            pixel_index: usize,
            row: usize,
            column: usize,
        };

        fn pixel_from_cycle(cycle:usize) Pixel {
            const c = cycle - 1;
            const frame = @divFloor(c, 240);
            const cycle_in_frame = c - (frame*240);
            const row = @divFloor(cycle_in_frame, 40);
            const column = cycle_in_frame - (row*40);
            const pixel_index = (row * 41) + column;
            return Pixel {
                .pixel_index = pixel_index, .row = row, .column = column
            };
        }
    };

    var screen: [Screen.screen_initial_state.len]u8 = undefined;
    std.mem.copy(u8, &screen, Screen.screen_initial_state);

    cpu = CPU.load_program(instructions.items);
    while (cpu.tick()) |reg_val| {
        const cycle = cpu.cycle;
        const brush_middle = reg_val;
        var pixel = Screen.pixel_from_cycle(cycle);
        if (@intCast(i32, pixel.column) >= brush_middle-1 and @intCast(i32, pixel.column) <= brush_middle+1) {
            screen[pixel.pixel_index] = '#';
        }
        if (debug) std.debug.print("{s}\n\n", .{screen});
    }
    
    // const solution: i32 = 0;
    std.debug.print("Advent Of Code 2022, day {d}, part {s}, input: {s}, solution:\n\n{s}\n", .{aoc.day, @tagName(aoc.part), @tagName(in), screen});
}
