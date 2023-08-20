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
    create_instance: std.meta.Child(c.PFN_vkCreateInstance),

    fn init() !Self {
        var library = try load_library();
        const get_instance_proc_addr = library.lookup(std.meta.Child(c.PFN_vkGetInstanceProcAddr), "vkGetInstanceProcAddr").?;
        const create_instance = @ptrCast(std.meta.Child(c.PFN_vkCreateInstance), get_instance_proc_addr(null, "vkCreateInstance"));
        return .{
            .handle = library,
            .get_instance_proc_addr = get_instance_proc_addr,
            .create_instance = create_instance,
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

    // sType: VkStructureType,
    // pNext: ?*const anyopaque,
    // flags: VkInstanceCreateFlags,
    // pApplicationInfo: [*c]const VkApplicationInfo,
    // enabledLayerCountL: u32,
    // ppEnabledLayerNames: [*c]const [*c]const u8,
    // enabledExtensionCount: u32,
    // ppEnabledExtensionNames: [*c]const [*c]const u8,

    const info = std.mem.zeroInit(c.VkInstanceCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
    });

    const allocation_callbacks = null;

    var instance: c.VkInstance = undefined;
    switch (entry.create_instance(&info, allocation_callbacks, &instance)) {
        c.VK_SUCCESS => {},
        else => undefined,
    }
}
