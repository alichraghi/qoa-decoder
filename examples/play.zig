const std = @import("std");
const sysaudio = @import("sysaudio");
const Qoa = @import("qoa");
const audio_file = @embedFile("assets/childhood.qoa");

var file_decoded: Qoa = undefined;
var player: sysaudio.Player = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var ctx = try sysaudio.Context.init(.pipewire, allocator, .{});
    defer ctx.deinit();
    try ctx.refresh();
    const device = ctx.defaultDevice(.playback) orelse return error.NoDevice;

    file_decoded = try Qoa.decode(allocator, audio_file);
    defer allocator.free(file_decoded.samples);
    if (file_decoded.num_channels > device.channels.len) {
        return error.InvalidDevice;
    }

    player = try ctx.createPlayer(device, writeCallback, .{ .format = .i16 });
    defer player.deinit();
    try player.start();

    try player.setVolume(0.75);

    var buf: [16]u8 = undefined;
    while (true) {
        std.debug.print("( paused = {}, volume = {d} )\n> ", .{ player.paused(), try player.volume() });
        const line = (try std.io.getStdIn().reader().readUntilDelimiterOrEof(&buf, '\n')) orelse break;
        var iter = std.mem.split(u8, line, ":");
        const cmd = std.mem.trimRight(u8, iter.first(), &std.ascii.whitespace);
        if (std.mem.eql(u8, cmd, "vol")) {
            var vol = try std.fmt.parseFloat(f32, std.mem.trim(u8, iter.next().?, &std.ascii.whitespace));
            try player.setVolume(vol);
        } else if (std.mem.eql(u8, cmd, "pause")) {
            try player.pause();
            try std.testing.expect(player.paused());
        } else if (std.mem.eql(u8, cmd, "play")) {
            try player.play();
            try std.testing.expect(!player.paused());
        } else if (std.mem.eql(u8, cmd, "exit")) {
            break;
        }
    }
}

var i: usize = 0;
fn writeCallback(_: ?*anyopaque, frames: usize) void {
    for (0..frames) |fi| {
        if (i >= file_decoded.samples.len) i = 0;
        for (0..file_decoded.num_channels) |ch| {
            player.write(player.channels()[ch], fi, file_decoded.samples[i]);
            i += 1;
        }
    }
}
