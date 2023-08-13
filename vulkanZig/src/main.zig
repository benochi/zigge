const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig");

const Entry = struct {
    const Self = @This();
    const LibraryNames = switch (builtin.os.tag) {
        .windows => &[_][]const u8{"vulkan-1.dll"},
        .ios, .macos, .tvos, .watchos => &[_][]const u8{ "libvulkan.dylib", "libvulkan.1.dylib", "libMoltenVK.dylib" },
        else => &[_][]const u8{ "libvulkan.so", "libvulkan.so.1" },
    };

    handle: std.DynLib,
    get_instance_proc_addr: std.meta.Child(c.PFN_vkGetInstanceProcAddr),

    fn init() !Self {
        var library = try load_library();
        return .{
            .handle = library,
            .get_instance_proc_addr = library.lookup(std.meta.Child(c.PFN_vkGetInstanceProcAddr), "vkGetInstanceProcAddr").?,
        };
    }

    fn deinit(self: *Self) void {
        self.handle.close();
    }

    fn load_library() !std.DynLib {
        for (LibraryNames) |library_name| {
            return std.DynLib.open(library_name) catch continue;
        }
        return error.NotFound;
    }
};

pub fn main() !void {
    var entry = try Entry.init();
    defer entry.deinit();
}
