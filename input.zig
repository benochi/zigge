//handle all input, from keyboard, mouse, mousewheel, strafing, zoom in out, overhead, etc in editor. right click.
const std = @import("std");

pub fn handleInput() !void {
    // Create a buffer to hold the input
    var buffer: [1]u8 = undefined;

    // Read a single byte from standard input
    const byte_count = try std.io.getStdIn().read(buffer[0..]);
    if (byte_count > 0) {
        // If we read a byte, print a message based on the input
        switch (buffer[0]) {
            'w' => std.debug.print("You pressed W\n", .{}),
            'a' => std.debug.print("You pressed A\n", .{}),
            's' => std.debug.print("You pressed S\n", .{}),
            'd' => std.debug.print("You pressed D\n", .{}),
            else => std.debug.print("You pressed another key\n", .{}),
        }
    }
}
