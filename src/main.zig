const std = @import("std");

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

const Color = struct {
    r: u8,
    g: u8,
    b: u8,
};

const Image = struct {
    width: u16,
    height: u16,
    pixels: []Color,

    pub fn setColor(self: Image, x: u16, y: u16, color: Color) void {
        if (x >= self.width or y >= self.height) return;
        self.pixels[self.width * y + x] = color;
    }

    pub fn fillWithColor(self: *Image, color: Color) void {
        for (self.pixels) |*pixel| {
            pixel.* = color;
        }
    }

    pub fn getPixel(self: Image, x: u16, y: u16) ?Color {
        if (x >= self.width or y >= self.height) return null;
        return self.pixels[self.width * y + x];
    }
};

fn drawImage(image: Image) void {
    for (0..image.height) |y| {
        for (0..image.width) |x| {
            const color: u8 = image.getPixel(@intCast(x), @intCast(y)).?;
            std.debug.print("{c}", .{color});
        }
        std.debug.print("\n", .{});
    }
}

const Circle = struct {
    x: u16,
    y: u16,
    r: u16,

    pub fn containsPoint(self: Circle, x: u16, y: u16) bool {
        const dx = @as(i32, x) - @as(i32, self.x);
        const dy = @as(i32, y) - @as(i32, self.y);
        const distance_squared = dx * dx + dy * dy;
        const radius_squared = @as(i32, self.r) * @as(i32, self.r);
        return distance_squared <= radius_squared;
    }
};

fn drawFilledCircle(image: Image, circle: Circle, color: Color) void {
    for (0..image.height) |y| {
        for (0..image.width) |x| {
            const xi: u16 = @intCast(x);
            const yi: u16 = @intCast(y);
            if (circle.containsPoint(xi, yi)) {
                image.setColor(xi, yi, color);
            }
        }
    }
}

fn outputImageInPPM(image: Image) !void {
    const magicNumber = "P3";
    const maxChannelValue = 255;
    try stdout.print("{s}\n", .{magicNumber});
    try stdout.print("{d} {d}\n", .{ image.width, image.height });
    try stdout.print("{d}\n", .{maxChannelValue});
    for (0..image.height) |y| {
        for (0..image.width) |x| {
            const pixel = image.getPixel(@intCast(x), @intCast(y)).?;
            try stdout.print("{d} {d} {d}\n", .{ pixel.r, pixel.g, pixel.b });
        }
    }
}

pub fn main() !void {
    const width = 150;
    const height = 150;

    var colors: [width * height]Color = undefined;
    var image = Image{ .width = width, .height = height, .pixels = &colors };
    image.fillWithColor(.{ .r = 0, .g = 255, .b = 0 });

    // x^2 + y^2 = r^2
    const circle = Circle{ .x = 50, .y = 50, .r = 30 };
    drawFilledCircle(image, circle, .{ .r = 255, .g = 255, .b = 255 });

    try outputImageInPPM(image);
}
