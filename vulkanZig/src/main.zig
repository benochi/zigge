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

const Instance = struct {
    const Self = @This();
    handle: c.VkInstance,
    destroy_instance: std.meta.Child(c.PFN_vkDestroyInstance),
    allocation_callbacks: ?*c.VkAllocationCallbacks,

    fn init(entry: Entry, allocation_callbacks: ?*c.VkAllocationCallbacks) !Self {
        const info = std.mem.zeroInit(c.VkInstanceCreateInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        });
        var instance: c.VkInstance = undefined;
        switch (entry.create_instance(&info, allocation_callbacks, &instance)) {
            c.VK_SUCCESS => {
                const destroy_instance = @ptrCast(std.meta.Child(c.PFN_vkDestroyInstance), entry.get_instance_proc_addr(instance, "vkDestroyInstance"));
                return .{
                    .handle = instance,
                    .destroy_instance = destroy_instance,
                    .allocation_callbacks = allocation_callbacks,
                };
            },
            else => unreachable,
        }
    }

    fn deinit(self: Self) void {
        self.destroy_instance(
            self.handle,
            self.allocation_callbacks,
        );
    }
};

pub fn main() !void {
    var entry = try Entry.init();
    defer entry.deinit();

    const instance = try Instance.init(entry, null);
    defer instance.deinit();
}
