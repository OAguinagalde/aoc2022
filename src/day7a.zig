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
        index: DirectoryIdentifier,
        parent: ?DirectoryIdentifier,
        directories: std.ArrayList(DirectoryIdentifier),
        files: std.ArrayList(FileIdentifier),
    };

    /// represents the index where the name starts in `names_storage` + the length of the name
    const Name = struct {
        at: usize,
        len: usize
    };

    const DirectoryIdentifier = usize;
    const FileIdentifier = usize;

    const FileSystemError = error {
        InvalidParentIndex,
        DirectoryNotFound,
        FileNotFound
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

    fn get_root(self: FileSystem) FileSystemError.DirectoryNotFound!DirectoryIdentifier {
        return if (self.directories.items.len > 0) self.directories.items[0] else FileSystemError.DirectoryNotFound;
    }

    fn get_directory(self: FileSystem, parent_dir: DirectoryIdentifier, directory_name: []u8) FileSystemError.DirectoryNotFound!DirectoryIdentifier {
        const parent: Directory = self.directories.items[parent_dir];
        for (parent.directories) |dir_id| {
            const name = get_name(dir_id);
            if (directory_name.len == name.len and std.ascii.startsWithIgnoreCase(name, directory_name)) {
                return dir_id;
            }
        }
        return FileSystemError.DirectoryNotFound;
    }

    fn get_path(self: FileSystem, dir_id: DirectoryIdentifier) []DirectoryIdentifier {
        var path = std.ArrayList(DirectoryIdentifier).init(self.allocator);
        defer path.clearAndFree();
        path.append(dir_id);
        while (self.directories.items[dir_id].parent) |parent| {
            path.append(parent);
            dir_id = parent;
        }
        std.mem.reverse(DirectoryIdentifier, path.items);
        return path.items[0..path.items.len];
    }

    fn get_name(self: FileSystem, dir_id: DirectoryIdentifier) []u8 {
        const dir: Directory = self.directories.items[dir_id];
        return self.names_storage.items[dir.name.at];
    }

    fn get_name(self: FileSystem, file_id: FileIdentifier) []u8 {
        const file: File = self.files.items[file_id];
        return self.names_storage.init[file.name.at];
    }

    fn get_size(self: FileSystem, file_id: FileIdentifier) usize {
        const file: File = self.files.items[file_id];
        return file.size;
    }

    fn get_file(self: FileSystem, location_id: DirectoryIdentifier, file_name: []u8) FileSystemError.FileNotFound!FileIdentifier {
        const parent_dir: Directory = self.directories.items[location_id];
        for (parent_dir.files) |file_id| {
            const name = get_name(file_id);
            if (name.len == file_name.len and std.ascii.startsWithIgnoreCase(name, file_name)) {
                return file_id;
            }
        }
        return FileSystemError.FileNotFound;
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

    const cwdError = error {
        FileSystemEmpty,
        AlreadyAtRoot
    };

    fn init(fs: *FileSystem, allocator: std.mem.Allocator) cwdError.FileSystemEmpty!CWD {
        return if (fs.get_root()) |root| {
            var cwd =  CWD {
                .cwd = std.ArrayList(FileSystem.DirectoryIdentifier).init(allocator)
            };
            cwd.cd(fs, root);
            return cwd;
        }
        else cwdError.FileSystemEmpty;
    }

    fn current_dir (self: *CWD) FileSystem.DirectoryIdentifier {
        return self.cwd.items[-1];
    }
    
    /// changes the current working directory and maps the filesystem as it goes
    fn cd(self: *CWD, fs: *FileSystem, dir: FileSystem.DirectoryIdentifier) cwdError.AlreadyAtRoot!void {
        if (std.ascii.startsWithIgnoreCase(directory, "..")) {
            if (cwd.items.len <= 1) return cwdError.AlreadyAtRoot;
            self.cwd.pop();
        }
        else {
            const current = self.current_dir();
            // if directory is not in current directory, just rebuild the path
            try (fs.get_directory(current, dir)) catch |err| {
                const new_cwd = fs.get_path(dir);
                self.cwd.clearRetainingCapacity();
                try self.cwd.appendSlice(new_cwd);
                return;
            };
            try self.cwd.append(dir);
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
                const command = input[2..];
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
