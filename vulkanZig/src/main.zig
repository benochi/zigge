const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig");

fn GetFunctionPointer(comptime name: []const u8) type {
    return std.meta.Child(@field(c, "PFN_" ++ name));
}

fn lookup(library: *std.DynLib, comptime name: [:0]const u8) GetFunctionPointer(name) {
    return library.lookup(GetFunctionPointer(name), name).?;
}

fn load(comptime name: []const u8, proc_addr: anytype, handle: anytype) GetFunctionPointer(name) {
    return @ptrCast(GetFunctionPointer(name), proc_addr(handle, name.ptr));
}

fn load_library(library_names: []const []const u8) !std.DynLib {
    for (library_names) |library_name| {
        return std.DynLib.open(library_name) catch continue;
    }
    return error.NotFound;
}

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
        var library = try load_library(LibraryNames);
        const get_instance_proc_addr = lookup(&library, "vkGetInstanceProcAddr");
        const create_instance = load("vkCreateInstance", get_instance_proc_addr, null);
        return .{
            .handle = library,
            .get_instance_proc_addr = get_instance_proc_addr,
            .create_instance = create_instance,
        };
    }

    fn deinit(self: *Self) void {
        self.handle.close();
    }
};

const Instance = struct {
    const Self = @This();
    handle: c.VkInstance,
    allocation_callbacks: ?*c.VkAllocationCallbacks,
    destroy_instance: std.meta.Child(c.PFN_vkDestroyInstance),
    enumerate_physical_devices: std.meta.Child(c.PFN_vkEnumeratePhysicalDevices),

    fn init(entry: Entry, allocation_callbacks: ?*c.VkAllocationCallbacks) !Self {
        const info = std.mem.zeroInit(c.VkInstanceCreateInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        });
        var instance: c.VkInstance = undefined;
        return switch (entry.create_instance(&info, allocation_callbacks, &instance)) {
            c.VK_SUCCESS => .{
                .handle = instance,
                .destroy_instance = load("vkDestroyInstance", entry.get_instance_proc_addr, instance),
                .enumerate_physical_devices = load("vkEnumeratePhysicalDevices", entry.get_instance_proc_addr, instance),
                .allocation_callbacks = allocation_callbacks,
            },
            c.VK_ERROR_OUT_OF_HOST_MEMORY => error.OutOfHostMemory,
            c.VK_ERROR_OUT_OF_DEVICE_MEMORY => error.OutOfDeviceMemory,
            c.VK_ERROR_INITIALIZATION_FAILED => error.InitializationFailed,
            c.VK_ERROR_LAYER_NOT_PRESENT => error.LayerNotPresent,
            c.VK_ERROR_EXTENSION_NOT_PRESENT => error.ExtensionNotPresent,
            c.VK_ERROR_INCOMPATIBLE_DRIVER => error.IncompatibleDriver,
            else => unreachable,
        };
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

    instance.enumerate_physical_devices();
}
