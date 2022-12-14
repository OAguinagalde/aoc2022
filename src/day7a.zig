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
        size: usize
    };

    /// represents the index where the name starts in `names` + the length of the name
    const Name = struct {
        at: usize,
        len: usize
    };

    /// This FileSystem does not allow files or directories to be deleted lol
    const DirectoryIdentifier = usize;
    const FileIdentifier = usize;

    const NotFound = error.NotFound;
    const RootAlreadyExists = error.RootAlreadyExists;

    names: std.ArrayList(u8),
    /// The first item will always be the parent directory. If root, then it will be itself.
    directories: std.ArrayList(Directory),
    files: std.ArrayList(File),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) FileSystem {
        return FileSystem {
            .names = std.ArrayList(u8).init(allocator),
            .directories = std.ArrayList(Directory).init(allocator),
            .files = std.ArrayList(File).init(allocator),
            .allocator = allocator
        };
    }

    fn get_parent(self: *const FileSystem, dir: DirectoryIdentifier) DirectoryIdentifier {
        return self.directories.items[dir].directories.items[0];
    }

    fn get_root(self: *const FileSystem) !DirectoryIdentifier {
        return if (self.directories.items.len > 0) self.directories.items[0].index else NotFound;
    }

    /// TODO for now this is potentially O(n) where n is the number of directories inside `location`
    fn get_directory(self: *const FileSystem, location: DirectoryIdentifier, name: []const u8) error{NotFound}!DirectoryIdentifier {
        const parent: Directory = self.directories.items[location];
        
        if (name.len == 2 and std.ascii.startsWithIgnoreCase(name, "..")) {
            return parent.directories.items[0];
        }

        for (parent.directories.items) |dir_id, i| {
            
            if (i == 0) continue; // skip the first one since it will be the parent directory
            
            const dir_name = self.get_name(Directory, dir_id);
            if (dir_name.len == name.len and std.ascii.startsWithIgnoreCase(dir_name, name)) {
                return dir_id;
            }
        }
        return NotFound;
    }

    fn get_path(self: *const FileSystem, target: DirectoryIdentifier, buffer: []u8) ![]DirectoryIdentifier {
        var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(buffer);
        var path = std.ArrayList(DirectoryIdentifier).init(fixed_buffer_allocator.allocator());
        
        const root = try self.get_root();
        
        // Add the destination first
        var dir_added = target;
        try path.append(dir_added);

        // As long as the root has not been added, keep adding the parent
        while (root != dir_added) {
            const parent = self.get_parent(dir_added);
            try path.append(parent);
            dir_added = parent;
        }

        // Reverse the path so that it goes from root to target directory
        std.mem.reverse(DirectoryIdentifier, path.items);
        return path.items[0..path.items.len];
    }

    fn get_path_as_string(self: *const FileSystem, target: DirectoryIdentifier, buffer: []u8) ![]const u8 {
        var bunch_of_stack_memory: [1024*1]u8 = undefined;
        const path = try self.get_path(target, &bunch_of_stack_memory);
        
        // every path starts from the room naturally "/some/folder/path"
        if (path[0] != try self.get_root()) unreachable;

        // the index of the last character that has not been written
        var i: usize = 0;
        for (path) |dir, index| {
            if (index == 0) continue; // skip root since it is nameless, so basically '/', which is included in the element indexed 1
            
            // get the name of the directory
            const name = self.get_name(FileSystem.Directory, dir);
            
            const formatted = try std.fmt.bufPrint(buffer[i..], "/{s}", .{name});
            i += formatted.len;
        }

        return buffer[0..i];
    }

    fn get_file(self: *const FileSystem, location: DirectoryIdentifier, name: []const u8) error{NotFound}!FileIdentifier {
        const dir: Directory = self.directories.items[location];
        for (dir.files) |file| {
            const file_name = get_name(File, file);
            if (name.len == file_name.len and std.ascii.startsWithIgnoreCase(name, file_name)) {
                return file;
            }
        }
        return NotFound;
    }

    fn get_name(self: *const FileSystem, comptime target_type: anytype, item: usize) []const u8 {
        return switch (target_type) {
            Directory => self.names.items[self.directories.items[item].name.at..self.directories.items[item].name.at + self.directories.items[item].name.len],
            File => self.names.items[self.files.items[item].name.at..self.files.items[item].name.at+self.files.items[item].name.len],
            else => unreachable
        };
    }

    /// location should be null IIF its the FileSystem's root. There can only be 1 single root!
    /// TODO use specific errors error{RootAlreadyExists,anyerror}
    fn create_directory(self: *FileSystem, location: ?DirectoryIdentifier, name: []const u8) !DirectoryIdentifier {
        
        if (location == null and self.directories.items.len != 0) return RootAlreadyExists;
        
        var new_directory = Directory {
            .name = try self.save_name(name),
            .index = self.directories.items.len,
            .directories = std.ArrayList(usize).init(self.allocator),
            .files = std.ArrayList(usize).init(self.allocator),
            .size = 0
        };

        // Set the directory's parent
        if (location) |parent| {
            try new_directory.directories.append(parent);
            try self.directories.items[parent].directories.append(new_directory.index);
            // std.debug.print("created dir {s} at {s}\n", .{name, self.get_name(Directory, parent)});
        }
        else {
            // The root's parent directory is itself
            try new_directory.directories.append(new_directory.index);
            // std.debug.print("created dir {s} at /\n", .{name});
        }

        try self.directories.append(new_directory);

        return new_directory.index;
    }

    fn create_file(self: *FileSystem, location: DirectoryIdentifier, name: []const u8, size: usize) !FileIdentifier {
        var new_file = File {
            .name = try self.save_name(name),
            .index = self.files.items.len,
            .size = size,
        };
        try self.files.append(new_file);
        try self.directories.items[location].files.append(new_file.index);
        
        const root = try self.get_root();
        var current_dir = location;
        // propagate the size of the file towards root
        while (true) {
            
            // update size of dir
            var dir = self.directories.items[current_dir];
            dir.size += size;
            
            // if dir is root, finish propagation
            if (current_dir == root) break;

            // else, continue with parent
            const parent = self.get_parent(current_dir);
            current_dir = parent;
        }

        return new_file.index;
    }

    // TODO make an iterator that goes through every directory up to the root and use inside create_file, get_path, and find_solutions
    /// the directory `location` is will be the first item of the iterator, and `root` will be the last
    // fn iterator_to_root(self: *const FileSystem, location: DirectoryIdentifier) DirectoryIterator {
        
    // }

    /// make a copy of the name and return a representing Name object
    fn save_name(self: *FileSystem, name: []const u8) !Name {
        const index = self.names.items.len;
        // internally copies iwth std.mem.copy(u8, dest, slice);
        try self.names.appendSlice(name);
        return Name {
            .at = index, .len = name.len
        };
    }

    /// Lazily iterates over all the folders from the initial one (included) until the root (included) of the file system
    const DirectoryIterator = struct {
        
        fs: *const FileSystem,
        next: ?DirectoryIdentifier,
        first: DirectoryIdentifier,
        last: DirectoryIdentifier,
        
        const Self = @This();

        /// gets the next directory of the iterator
        pub fn next(self: *Self) ?DirectoryIdentifier {
            const current = self.next;
            if (current == null) return null;
            
            // update the next one to the parent (except if its the root)
            const parent = self.fs.get_parent(current);
            self.next = if (current == parent) null else parent;
            
            return current;
        }

        /// Resets the iterator to the initial token.
        pub fn reset(self: *Self) void {
            self.next = self.first;
        }

        // pub fn peek(self: *Self) ?DirectoryIdentifier { }
        // pub fn rest(self: Self) []const DirectoryIdentifier { }

    };
};

const PathTracker = struct {

    path: std.ArrayList(FileSystem.DirectoryIdentifier),
    fs: *const FileSystem,

    const FileSystemEmpty = error.FileSystemEmpty;

    /// The FileSystem must be an initialized FileSystem which already has a root defined
    /// TODO specify error error{FileSystemEmpty}
    fn init(fs: *const FileSystem, allocator: std.mem.Allocator) !PathTracker {
        return if (fs.get_root()) |root| {
            var path_tracker =  PathTracker {
                .fs = fs,
                .path = std.ArrayList(FileSystem.DirectoryIdentifier).init(allocator)
            };
            try path_tracker.path.append(root);
            return path_tracker;
        }
        else |_| FileSystemEmpty;
    }

    fn cwd(self: *const PathTracker) FileSystem.DirectoryIdentifier {
        return self.path.items[self.path.items.len-1];
    }
    
    fn cd(self: *PathTracker, dir: FileSystem.DirectoryIdentifier) !void {
        
        const current = self.cwd();

        // There is 3 options:
        // 1. it's current's parent dir
        if (self.fs.get_parent(current) == dir) {
            _ = self.path.pop();
        }
        
        // 2. it's current's child dir
        else if (self.fs.get_parent(dir) == current) {
            try self.path.append(dir);
        }
        
        // 3. it's a none of those (but still a valid dir)
        else |err| switch (err) {
            // If the dir doesn't exist, in the current directory, just rebuild the path
            FileSystem.NotFound => {
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
    // const mode = Input.Real;

    var input_file = comptime std.fmt.comptimePrint("input/{d}/{s}.txt", .{day, switch (mode) { .Example => "example", .Real => "input" }});
    
    var bunch_of_stack_memory: [1024*1000]u8 = undefined;
    var fixed_buffer_allocator = std.heap.FixedBufferAllocator.init(&bunch_of_stack_memory);
    
    var fs = FileSystem.init(fixed_buffer_allocator.allocator());
    var path_tracker: ?PathTracker = null;

    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var file_read_buffer: [1024]u8 = undefined;
    while (try buf_reader.reader().readUntilDelimiterOrEof(&file_read_buffer, '\n')) |line| {
        if (line.len == 0) continue; // ignore empty lines
        switch (line[0]) {
            '$' => {
                const command = line[2..];
                if (std.mem.eql(u8, command[0..2], "cd")) {
                    const directory = command[3..];
                    if (path_tracker) |*path| {

                        const location = path.cwd();
                        
                        var buffer: [1024*1]u8 = undefined;
                        const path_as_string = try fs.get_path_as_string(location, &buffer);
                        std.debug.print("$ {s}> cd {s}\n", .{path_as_string, directory[0..]});
                        
                        // If directory doesn't exist create it
                        const dir = fs.get_directory(location, directory) catch |err| switch (err) {
                            FileSystem.NotFound => try fs.create_directory(location, directory)
                        };

                        try path.cd(dir);
                    }
                    else {
                        // Its the root then
                        _ = try fs.create_directory(null, directory);
                        std.debug.print("$ /> \n", .{});
                        path_tracker = try PathTracker.init(&fs, fixed_buffer_allocator.allocator());
                    }
                }
            },
            else => {
                var iterator = std.mem.tokenize(u8, line, " ");
                const first_token = iterator.next().?;
                if (std.ascii.isDigit(first_token[0])) {
                    const size = try std.fmt.parseInt(usize, first_token, 10);
                    const file_name = iterator.next().?;
                    const current_directory = path_tracker.?.cwd();
                    
                    var buffer: [1024*1]u8 = undefined;
                    const path_as_string = try fs.get_path_as_string(current_directory, &buffer);
                    std.debug.print("$ {s}> touch {s} ({d})\n", .{path_as_string, file_name, size});

                    _ = try fs.create_file(current_directory, file_name, size);
                }
                else {
                    const current_directory = path_tracker.?.cwd();
                    const directory = iterator.next().?;
                    const dir = fs.get_directory(current_directory, directory) catch |err| switch (err) {
                        FileSystem.NotFound => try fs.create_directory(current_directory, directory)
                    };
                    _ = dir;
                }
            }
        }
    }

    std.debug.print("{d}{s} -> {}\n", .{day, @tagName(part), 0});
}
