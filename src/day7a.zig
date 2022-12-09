const std = @import("std");

const ThisFile = @This();
const Input = enum { Example, Real };
const Part = enum { a, b };

const FileSystem = struct {

    const File = struct {
        index: FileIdentifier,
        size: usize,
        name: Name
    };

    const Directory = struct {
        name: Name,
        index: ?DirectoryIdentifier,
        parent: DirectoryIdentifier,
        directories: std.ArrayList(usize),
        files: std.ArrayList(usize),
    };

    /// represents the index where the name starts in `names_storage` + the length of the name
    const Name = struct {
        at: usize,
        len: usize
    };

    const DirectoryIdentifier = usize;
    const FileIdentifier = usize;

    const FileSystemError = error {
        InvalidParentIndex
    };

    names_storage: std.ArrayList(u8),
    directories: std.ArrayList(Directory),
    files: std.ArrayList(File),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) FileSystem {
        return FileSystem {
            .names_storage = std.ArrayList(u8).init(allocator),
            .directories = std.ArrayList(Directory).init(allocator),
            .files = std.ArrayList(Directory).init(allocator),
            .allocator = allocator
        };
    }

    fn create_directory(self: *FileSystem, parent_index: ?DirectoryIdentifier, name: []u8) FileSystemError.InvalidParentIndex!DirectoryIdentifier {
        if (parent_index == null and self.directories.items.len != 0) return FileSystemError.InvalidParentIndex;
        var new_directory = Directory {
            .name = save_name(name),
            .index = self.directories.items.len,
            .parent = parent_index,
            .directories = std.ArrayList(usize).init(self.allocator),
            .files = std.ArrayList(usize).init(self.allocator),
        };
        try self.directories.append(new_directory);
        if (parent_index != null) try self.directories.items[parent_index].directories.append(new_directory.index);
        return new_directory.index;
    }

    fn create_file(self: *FileSystem, parent_index: DirectoryIdentifier, name: []u8, file_size: usize) FileSystemError.InvalidParentIndex!FileIdentifier {
        var new_file = File {
            .name = save_name(name),
            .index = self.files.items.len,
            .size = file_size,
        };
        try self.files.append(new_file);
        try self.directories.items[parent_index].files.append(new_file.index);
        return new_file.index;
    }

    /// make a copy of the name and return a representing Name object
    fn save_name(self: *FileSystem, name: []u8) Name {
        const index = self.name_storage.items.len;
        var allocated_space = try self.name_storage.addManyAsArray(name.len);
        std.mem.copy(u8, allocated_space, name);
        return Name {
            .at = index, .len = name.len
        };
    }
};

const CWD = struct {

    cwd: std.ArrayList(FileSystem.DirectoryIdentifier),

    fn init(allocator: std.mem.Allocator) CWD {
        return CWD {
            .cwd = std.ArrayList(FileSystem.DirectoryIdentifier).init(allocator)
        };
    }
    
    /// changes the current working directory and maps the filesystem as it goes
    fn cd(self: *CWD, fs: *FileSystem, directory_name: []u8) void {
        if (std.ascii.startsWithIgnoreCase(directory, "..")) {
            self.cwd.pop();
        }
        else {
            var current = null;
            if (cwd.items.len > 0) {
                current = cwd.items[-1];
            }
            else {
                // moving into the root! AKA initialize the cwd
            }
            var dir_id = try fs.create_directory(current, directory_name);
            try self.cwd.append(dir_id);
        }
    }
    
};

pub fn run() !void {
    
    const day: usize = 7;
    const part = Part.a;
    const mode = Input.Example;

    var input_file = comptime std.fmt.comptimePrint("input/{d}/{s}.txt", .{day, switch (mode) { .Example => "example", .Real => "input" }});
    
    var bunch_of_stack_memory: [1024*2]u8 = undefined;
    var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(&bunch_of_stack_memory);
    
    var cwd = CWD.init(fixed_buffer_allocator.allocator());
    var fs = FileSystem.init(fixed_buffer_allocator.allocator());

    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var file_read_buffer: [1024]u8 = undefined;
    while (try buf_reader.reader().readUntilDelimiterOrEof(&file_read_buffer, '\n')) |line| { // line doesnt contain the delimiter '\n'
        if (line.len == 0) continue; // ignore empty lines
        const input = line;
        
        switch (input[0]) {
            '$' => {
                if (std.ascii.startsWithIgnoreCase(command, "cd")) {
                    const identifier = command[3..];
                    cwd.cd(fs, identifier);
                }
            },
            _ => {
                // TODO numbers file_name => fs.create_file()
                // TODO dir name => fs.create_directory()
            }
        }
    }

    std.debug.print("{d}{s} -> {}\n", .{day, @tagName(part), 0});
}
