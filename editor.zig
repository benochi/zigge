//handles editor loop for construction game elements.  Should allow creation of new game directories and files and linking them together.
//should handle building the game into an exe.  Should run tests to ensure the game is runable and handle different OSs if needed.
const std = @import("std");
const Input = @import("input.zig");
const graphics = @import("graphics.zig");
const window = @import("window.zig");
const audio = @import("audio.zig");
const collision = @import("collision.zig");
const es = @import("editorSettings.zig");

pub fn main() !void {
    std.debug.print("Engine started\n", .{});

    // Use something from input.zig here. For example, if input.zig defines a function called handleInput:
    try Input.handleInput();
}
