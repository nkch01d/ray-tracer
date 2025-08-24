const std = @import("std");

var stdout_buffer: [5120]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

const Color = struct {
    const BLACK = Color{ .r = 0, .g = 0, .b = 0 };
    const WHITE = Color{ .r = 255, .g = 255, .b = 255 };
    const BLUE = Color{ .r = 0, .g = 0, .b = 255 };
    const GREEN = Color{ .r = 0, .g = 255, .b = 0 };
    const RED = Color{ .r = 255, .g = 0, .b = 0 };

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
        const index: usize = @as(usize, self.width) * @as(usize, y) + @as(usize, x);
        self.pixels[index] = color;
    }

    pub fn fillWithColor(self: *Image, color: Color) void {
        for (self.pixels) |*pixel| {
            pixel.* = color;
        }
    }

    pub fn getPixel(self: Image, x: u16, y: u16) ?Color {
        if (x >= self.width or y >= self.height) return null;
        const index: usize = @as(usize, self.width) * @as(usize, y) + @as(usize, x);
        return self.pixels[index];
    }
};

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

fn drawFilledHorizontalGradientCircle(image: Image, circle: Circle, gradientBegin: Color, gradientEnd: Color) void {
    for (0..image.height) |y| {
        for (0..image.width) |x| {
            const xi: u16 = @intCast(x);
            const yi: u16 = @intCast(y);
            if (circle.containsPoint(xi, yi)) {
                // TODO: fix me
                // First we need to find x coordinate in terms of coordinate spaces of the circle (can be negative)
                const x_circle: i32 = @as(i32, @as(i32, @intCast(circle.x)) - @as(i32, @intCast(x)));
                const width = circle.r * 2;

                // const some_var: f32 = if (x_circle >= 0) 0.5 else 0;
                const percent: f32 = @abs(@as(f32, @floatFromInt(x_circle)) / @as(f32, @floatFromInt(width - 1)));

                const r = gradientBegin.r + @as(u8, @intFromFloat(@as(f32, @floatFromInt(gradientEnd.r - gradientBegin.r)) * percent));
                const g = gradientBegin.g + @as(u8, @intFromFloat(@as(f32, @floatFromInt(gradientEnd.g - gradientBegin.g)) * percent));
                const b = gradientBegin.b + @as(u8, @intFromFloat(@as(f32, @floatFromInt(gradientEnd.b - gradientBegin.b)) * percent));
                image.setColor(xi, yi, .{ .r = r, .g = g, .b = b });
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
    try stdout.flush();
}

pub fn main() !void {
    const width = 1024;
    const height = 1024;

    // TODO: we should use allocator for that, when we will need to support user defined sizes
    var colors: [width * height]Color = undefined;
    var image = Image{ .width = width, .height = height, .pixels = &colors };
    image.fillWithColor(Color.WHITE);

    const circle = Circle{ .x = 500, .y = 500, .r = 200 };
    drawFilledHorizontalGradientCircle(image, circle, Color.RED, Color.WHITE);

    try outputImageInPPM(image);
}
