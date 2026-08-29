const std = @import("std");

pub const KeyboardLayout = enum {
    persian,
    english,
};

const Pair = struct {
    fa: u21,
    en: u21,
};

const pairs = [_]Pair{
    .{ .fa = 0x0636, .en = 'q' },
    .{ .fa = 0x0635, .en = 'w' },
    .{ .fa = 0x062B, .en = 'e' },
    .{ .fa = 0x0642, .en = 'r' },
    .{ .fa = 0x0641, .en = 't' },
    .{ .fa = 0x063A, .en = 'y' },
    .{ .fa = 0x0639, .en = 'u' },
    .{ .fa = 0x0647, .en = 'i' },
    .{ .fa = 0x062E, .en = 'o' },
    .{ .fa = 0x062D, .en = 'p' },
    .{ .fa = 0x062C, .en = '[' },
    .{ .fa = 0x0686, .en = ']' },
    .{ .fa = 0x067E, .en = '\\' },
    .{ .fa = 0x0634, .en = 'a' },
    .{ .fa = 0x0633, .en = 's' },
    .{ .fa = 0x06CC, .en = 'd' },
    .{ .fa = 0x0628, .en = 'f' },
    .{ .fa = 0x0644, .en = 'g' },
    .{ .fa = 0x0627, .en = 'h' },
    .{ .fa = 0x062A, .en = 'j' },
    .{ .fa = 0x0646, .en = 'k' },
    .{ .fa = 0x0645, .en = 'l' },
    .{ .fa = 0x06A9, .en = ';' },
    .{ .fa = 0x06AF, .en = '\'' },
    .{ .fa = 0x0638, .en = 'z' },
    .{ .fa = 0x0637, .en = 'x' },
    .{ .fa = 0x0632, .en = 'c' },
    .{ .fa = 0x0631, .en = 'v' },
    .{ .fa = 0x0630, .en = 'b' },
    .{ .fa = 0x062F, .en = 'n' },
    .{ .fa = 0x0626, .en = 'm' },
    .{ .fa = 0x0648, .en = ',' },
};

fn lookup(fa_to_en: bool, cp: u21) ?u21 {
    for (pairs) |p| {
        if (fa_to_en) {
            if (p.fa == cp) return p.en;
        } else {
            if (p.en == cp) return p.fa;
        }
    }
    return null;
}

fn appendCodepoint(out: *std.ArrayList(u8), cp: u21) !void {
    var buf: [4]u8 = undefined;
    const n = try std.unicode.utf8Encode(cp, &buf);
    try out.appendSlice(buf[0..n]);
}

// ✅ تشخیص خودکار زبان متن
pub fn detectLayout(text: []const u8) KeyboardLayout {
    var view = std.unicode.Utf8View.init(text) catch return .english;
    var it = view.iterator();
    while (it.nextCodepoint()) |cp| {
        // محدوده حروف عربی/فارسی + حروف فارسی خاص
        if ((cp >= 0x0600 and cp <= 0x06FF) or (cp >= 0xFB50 and cp <= 0xFEFF)) {
            return .persian;
        }
    }
    return .english;
}

pub fn convertText(text: []const u8, from: KeyboardLayout, to: KeyboardLayout, allocator: std.mem.Allocator) ![]u8 {
    _ = to;
    const fa_to_en = (from == .persian);

    var out = std.ArrayList(u8).init(allocator);
    errdefer out.deinit();

    var view = try std.unicode.Utf8View.init(text);
    var it = view.iterator();
    while (it.nextCodepoint()) |cp| {
        if (lookup(fa_to_en, cp)) |mapped| {
            try appendCodepoint(&out, mapped);
        } else {
            try appendCodepoint(&out, cp);
        }
    }

    return out.toOwnedSlice();
}

pub fn convertTextPreserveCase(text: []const u8, from: KeyboardLayout, to: KeyboardLayout, allocator: std.mem.Allocator) ![]u8 {
    _ = to;
    const fa_to_en = (from == .persian);

    var out = std.ArrayList(u8).init(allocator);
    errdefer out.deinit();

    var view = try std.unicode.Utf8View.init(text);
    var it = view.iterator();
    while (it.nextCodepoint()) |cp| {
        const is_upper = (cp >= 'A' and cp <= 'Z');
        const base = if (is_upper) cp + 32 else cp;

        if (lookup(fa_to_en, base)) |mapped0| {
            const mapped = if (is_upper and mapped0 >= 'a' and mapped0 <= 'z') mapped0 - 32 else mapped0;
            try appendCodepoint(&out, mapped);
        } else {
            try appendCodepoint(&out, cp);
        }
    }

    return out.toOwnedSlice();
}
