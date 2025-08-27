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

const Canvas = struct {
    width: u16,
    height: u16,
    pixels: []Color,

    pub fn setColor(self: Canvas, x: u16, y: u16, color: Color) void {
        if (x >= self.width or y >= self.height) return;
        const index: usize = @as(usize, self.width) * @as(usize, y) + @as(usize, x);
        self.pixels[index] = color;
    }

    pub fn getPixel(self: Canvas, x: u16, y: u16) ?Color {
        if (x >= self.width or y >= self.height) return null;
        const index: usize = @as(usize, self.width) * @as(usize, y) + @as(usize, x);
        return self.pixels[index];
    }

    pub fn fillWithColor(self: *Canvas, color: Color) void {
        for (self.pixels) |*pixel| {
            pixel.* = color;
        }
    }

    pub fn fillWithHorizontalGradientColor(self: *Canvas, gradientBegin: Color, gradientEnd: Color) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                // TODO: let's try to reduce the number of casts, cuz it looks gross
                const percent: f32 = @as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(self.width));
                const r = @as(u8, @intCast(@as(i16, gradientBegin.r) + @as(i16, @intFromFloat(@as(f32, @floatFromInt(@as(i32, gradientEnd.r) - @as(i32, gradientBegin.r))) * percent))));
                const g = @as(u8, @intCast(@as(i16, gradientBegin.g) + @as(i16, @intFromFloat(@as(f32, @floatFromInt(@as(i32, gradientEnd.g) - @as(i32, gradientBegin.g))) * percent))));
                const b = @as(u8, @intCast(@as(i16, gradientBegin.b) + @as(i16, @intFromFloat(@as(f32, @floatFromInt(@as(i32, gradientEnd.b) - @as(i32, gradientBegin.b))) * percent))));
                self.setColor(@intCast(x), @intCast(y), .{ .r = r, .g = g, .b = b });
            }
        }
    }

    pub fn fillWithVerticalGradientColor(self: *Canvas, gradientBegin: Color, gradientEnd: Color) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                // TODO: let's try to reduce the number of casts, cuz it looks gross
                const percent: f32 = @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(self.width));
                const r = @as(u8, @intCast(@as(i16, gradientBegin.r) + @as(i16, @intFromFloat(@as(f32, @floatFromInt(@as(i32, gradientEnd.r) - @as(i32, gradientBegin.r))) * percent))));
                const g = @as(u8, @intCast(@as(i16, gradientBegin.g) + @as(i16, @intFromFloat(@as(f32, @floatFromInt(@as(i32, gradientEnd.g) - @as(i32, gradientBegin.g))) * percent))));
                const b = @as(u8, @intCast(@as(i16, gradientBegin.b) + @as(i16, @intFromFloat(@as(f32, @floatFromInt(@as(i32, gradientEnd.b) - @as(i32, gradientBegin.b))) * percent))));
                self.setColor(@intCast(x), @intCast(y), .{ .r = r, .g = g, .b = b });
            }
        }
    }

    pub fn drawFilledCircle(self: Canvas, circle: Circle, color: Color) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const xi: u16 = @intCast(x);
                const yi: u16 = @intCast(y);
                if (circle.containsPoint(xi, yi)) {
                    self.setColor(xi, yi, color);
                }
            }
        }
    }

    pub fn drawFilledHorizontalGradientCircle(self: Canvas, circle: Circle, gradientBegin: Color, gradientEnd: Color) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const xi: u16 = @intCast(x);
                const yi: u16 = @intCast(y);
                if (circle.containsPoint(xi, yi)) {
                    // Basically we just found relative x coordinate to the middle leftmost circle point
                    const circle_left = @as(i32, circle.x) - @as(i32, circle.r);
                    const x_relative: i32 = @as(i32, @intCast(x)) - circle_left;
                    const width = circle.r * 2;
                    const percent: f32 = @as(f32, @floatFromInt(x_relative)) / @as(f32, @floatFromInt(width));

                    // TODO: analyze why this approach didn't work
                    // remove these comments when you understand the problem that was with this approach
                    // Because we are using x coordinate of the circle coordinate space, the percent value varies in range [-1;1]
                    // So we need to normalize the percent value to be in range [0;1] to apply gradient
                    // const normalized_percent: f32 = (percent + 1) / 2;

                    // TODO: same with huge amount of casts here, figure out how to make this more clean
                    const r = @as(u8, @intCast(@as(i16, gradientBegin.r) + @as(i16, @intFromFloat(@as(f32, @floatFromInt(@as(i32, gradientEnd.r) - @as(i32, gradientBegin.r))) * percent))));
                    const g = @as(u8, @intCast(@as(i16, gradientBegin.g) + @as(i16, @intFromFloat(@as(f32, @floatFromInt(@as(i32, gradientEnd.g) - @as(i32, gradientBegin.g))) * percent))));
                    const b = @as(u8, @intCast(@as(i16, gradientBegin.b) + @as(i16, @intFromFloat(@as(f32, @floatFromInt(@as(i32, gradientEnd.b) - @as(i32, gradientBegin.b))) * percent))));
                    self.setColor(xi, yi, .{ .r = r, .g = g, .b = b });
                }
            }
        }
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

fn outputCanvasInPPM(canvas: Canvas) !void {
    const magicNumber = "P3";
    const maxChannelValue = 255;
    try stdout.print("{s}\n", .{magicNumber});
    try stdout.print("{d} {d}\n", .{ canvas.width, canvas.height });
    try stdout.print("{d}\n", .{maxChannelValue});
    for (0..canvas.height) |y| {
        for (0..canvas.width) |x| {
            const pixel = canvas.getPixel(@intCast(x), @intCast(y)).?;
            try stdout.print("{d} {d} {d}\n", .{ pixel.r, pixel.g, pixel.b });
        }
    }
    try stdout.flush();
}

// TODO: think about using @Vector with SIMD optimizations in the future
pub fn Vec3(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        const Self = @This();

        pub fn init(x: T, y: T, z: T) Self {
            return Self{ .x = x, .y = y, .z = z };
        }

        pub fn add(a: Self, b: Self) Self {
            return Self{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
        }

        pub fn sub(a: Self, b: Self) Self {
            return Self{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
        }

        pub fn scale(a: Self, scalar: T) Self {
            return Self{ .x = a.x * scalar, .y = a.y * scalar, .z = a.z * scalar };
        }

        pub fn addMut(self: *Self, other: Self) void {
            self.x += other.x;
            self.y += other.y;
            self.z += other.z;
        }

        pub fn subMut(self: Self, other: Self) void {
            self.x -= other.x;
            self.y -= other.y;
            self.z -= other.z;
        }

        pub fn scaleMut(self: Self, scalar: T) void {
            self.x *= scalar;
            self.y *= scalar;
            self.z *= scalar;
        }

        pub fn dot(a: Self, b: Self) T {
            return a.x * b.x + a.y * b.y + a.z * b.z;
        }
    };
}

const Vec3f = Vec3(f32);
const Vec3i = Vec3(i32);

const Shape = union(enum) {
    sphere: Sphere,
};

const Sphere = struct {
    pos: Vec3i,
    r: u32,
};

const Camera = struct {
    pos: Vec3i,
};

const Scene = struct {
    camera: Camera,
    shapes: []Shape,
};

const Renderer = struct {
    scene: Scene,
    canvas: Canvas,

    const Self = @This();
    pub fn renderWithRayTracing(_: Self) void {}
};

pub fn main() !void {
    const width = 1024;
    const height = 1024;

    // TODO: we should use allocator for that, when we will need to support user defined sizes
    var colors: [width * height]Color = undefined;
    var canvas = Canvas{ .width = width, .height = height, .pixels = &colors };
    canvas.fillWithVerticalGradientColor(Color.WHITE, Color.RED);

    const circle = Circle{ .x = 500, .y = 500, .r = 200 };
    canvas.drawFilledHorizontalGradientCircle(circle, Color.WHITE, Color.RED);

    try outputCanvasInPPM(canvas);
}
