const std = @import("std");
const c = @import("c.zig");

const Entry = struct {
    const Self = @This();
    const LibraryNames = switch (builtin.os.tag) {
      .windows => & [_][]const u8{"vulkan-1.dll"},
      .ios, .macos, .tvos, .watchos => &[_][]const u8{"libvulkan.dylib", "libvulkan.1.dylib", "libMoltenVK.dylib"},
      else => &[_][]const u8{"libvulkan.so", "libvulkan.so.1"},
    };

    fn init() !Self{ 
      const library = std.DynLib.open(get_library_name());
    }

    fn deinit() void {

    }

    fn get_library_name(){

    }
};

pub fn main() !void {
    std.DynLib.open("");
}
