const std = @import("std");

const ThisFile = @This();
const Input = enum { Example, Real };
const Part = enum { a, b };

const FileSystem = struct {

    const File = struct {
        index: FileIdentifier,
        name: Name,
        size: usize
    };

    const Directory = struct {
        index: DirectoryIdentifier,
        name: Name,
        directories: std.ArrayList(DirectoryIdentifier),
        files: std.ArrayList(FileIdentifier),
    };

    /// represents the index where the name starts in `names` + the length of the name
    const Name = struct {
        at: usize,
        len: usize
    };

    /// This FileSystem does not allow files or directories to be deleted lol
    const DirectoryIdentifier = usize;
    const FileIdentifier = usize;

    const Errors = error {
        NotFound,
        RootAlreadyExists
    };

    names: std.ArrayList(u8),
    /// The first item will always be the parent directory. If root, then it will be itself.
    directories: std.ArrayList(Directory),
    files: std.ArrayList(File),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) FileSystem {
        return FileSystem {
            .names = std.ArrayList(u8).init(allocator),
            .directories = std.ArrayList(Directory).init(allocator),
            .files = std.ArrayList(Directory).init(allocator),
            .allocator = allocator
        };
    }

    fn get_parent(self: FileSystem, dir: DirectoryIdentifier) DirectoryIdentifier {
        return self.directories.items[dir].directories[0];
    }

    fn get_root(self: FileSystem) Errors.NotFound!DirectoryIdentifier {
        return if (self.directories.items.len > 0) self.directories.items[0] else Errors.NotFound;
    }

    /// TODO for now this is potentially O(n) where n is the number of directories inside `location`
    fn get_directory(self: FileSystem, location: DirectoryIdentifier, name: []u8) Errors.NotFound!DirectoryIdentifier {
        const parent: Directory = self.directories.items[location];
        
        if (name.len == 2 and std.ascii.startsWithIgnoreCase(name, "..")) {
            return parent.directories.items[0];
        }

        for (parent.directories) |dir_id, i| {
            
            if (i == 0) continue; // skip the first one since it will be the parent directory
            
            const dir_name = get_name(dir_id);
            if (dir_name.len == name.len and std.ascii.startsWithIgnoreCase(dir_name, name)) {
                return dir_id;
            }
        }
        return Errors.NotFound;
    }

    fn get_path(self: FileSystem, target: DirectoryIdentifier) []DirectoryIdentifier {
        var path = std.ArrayList(DirectoryIdentifier).init(self.allocator);
        defer path.clearAndFree();
        
        const root = try self.get_root();
        
        // Add the destination first
        var dir_added = target;
        path.append(dir_added);

        // As long as the root has not been added, keep adding the parent
        while (root != dir_added) {
            const parent = self.get_parent(dir_added);
            path.append(parent);
            dir_added = parent;
        }

        // Reverse the path so that it goes from root to target directory
        std.mem.reverse(DirectoryIdentifier, path.items);
        return path.items[0..path.items.len];
    }

    fn get_file(self: FileSystem, location: DirectoryIdentifier, name: []u8) Errors.NotFound!FileIdentifier {
        const dir: Directory = self.directories.items[location];
        for (dir.files) |file| {
            const file_name = get_name(file);
            if (name.len == file_name.len and std.ascii.startsWithIgnoreCase(name, file_name)) {
                return file;
            }
        }
        return Errors.NotFound;
    }

    fn get_name(self: FileSystem, directory: DirectoryIdentifier) []u8 {
        return self.names_storage.items[self.directories.items[directory].name.at];
    }

    fn get_name(self: FileSystem, file: FileIdentifier) []u8 {
        return self.names_storage.init[self.files.items[file].name.at];
    }

    fn get_size(self: FileSystem, file: FileIdentifier) usize {
        return self.files.items[file].size;
    }

    /// location should be null IIF its the FileSystem's root. There can only be 1 single root!
    fn create_directory(self: *FileSystem, location: ?DirectoryIdentifier, name: []u8) Errors.RootAlreadyExists!DirectoryIdentifier {
        
        if (location == null and self.directories.items.len != 0) return Errors.RootAlreadyExists;
        
        var new_directory = Directory {
            .name = save_name(name),
            .index = self.directories.items.len,
            .directories = std.ArrayList(usize).init(self.allocator),
            .files = std.ArrayList(usize).init(self.allocator),
        };

        // Set the directory's parent
        if (location) |parent| {
            try new_directory.directories.append(parent);
            try self.directories.items[parent].directories.append(new_directory.index);
        }
        else {
            // The root's parent directory is itself
            try new_directory.directories.append(new_directory.index);
        }

        try self.directories.append(new_directory);

        return new_directory.index;
    }

    fn create_file(self: *FileSystem, location: DirectoryIdentifier, name: []u8, size: usize) Errors.NotFound!FileIdentifier {
        var new_file = File {
            .name = save_name(name),
            .index = self.files.items.len,
            .size = size,
        };
        try self.files.append(new_file);
        try self.directories.items[location].files.append(new_file.index);
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

const PathTracker = struct {

    path: std.ArrayList(FileSystem.DirectoryIdentifier),
    fs: *FileSystem,

    const Errors = error {
        FileSystemEmpty
    };

    /// The FileSystem must be an initialized FileSystem which already has a root defined
    fn init(fs: FileSystem, allocator: std.mem.Allocator) Errors.FileSystemEmpty!PathTracker {
        return if (fs.get_root()) |root| {
            var path_tracker =  PathTracker {
                .path = std.ArrayList(FileSystem.DirectoryIdentifier).init(allocator)
            };
            path_tracker.cd(fs, root);
            return path_tracker;
        }
        else Errors.FileSystemEmpty;
    }

    fn cwd(self: PathTracker) FileSystem.DirectoryIdentifier {
        return self.path.items[-1];
    }
    
    fn cd(self: *PathTracker, dir: FileSystem.DirectoryIdentifier) void {
        
        const current = self.cwd();

        // There is 3 options:
        // 1. it's current's parent dir
        if (self.fs.get_parent(current) == dir) {
            self.path.pop();
        }
        
        // 2. it's current's child dir
        else if (self.fs.get_directory(current, dir)) |_| {
            try self.path.append(dir);
        }
        
        // 3. it's a none of those (but still a valid dir)
        else |err| switch (err) {
            // If the dir doesn't exist, in the current directory, just rebuild the path
            FileSystem.Errors.NotFound => {
                const path = self.fs.get_path(dir);
                self.path.clearRetainingCapacity();
                try self.path.appendSlice(path);
            }
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
    
    var fs: FileSystem = FileSystem.init(fixed_buffer_allocator.allocator());
    var path_tracker: ?PathTracker = null;

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
                    const directory = command[3..];
                    if (path_tracker) |path| {
                        
                        const location = path.current_dir();
                        
                        // If directory doesn't exist create it
                        const dir = fs.get_directory(location, directory) catch |err| switch (err) {
                            FileSystem.Errors.NotFound => fs.create_directory(location, directory)
                        };

                        path.cd(fs, dir);
                    }
                    else {
                        // Its the root then
                        const root = fs.create_directory(null, directory);
                        path_tracker = PathTracker.init(fs, fixed_buffer_allocator.allocator());
                    }
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
