const std = @import("std");

pub const KeyboardLayout = enum {
    persian,
    english,
};

const Pair = struct {
    fa: u21,
    en: u21,
};

// نقشه چیدمان استاندارد فارسی ↔ انگلیسی (بر اساس کدپوینت Unicode)
const pairs = [_]Pair{
    .{ .fa = 0x0636, .en = 'q' }, // ض
    .{ .fa = 0x0635, .en = 'w' }, // ص
    .{ .fa = 0x062B, .en = 'e' }, // ث
    .{ .fa = 0x0642, .en = 'r' }, // ق
    .{ .fa = 0x0641, .en = 't' }, // ف
    .{ .fa = 0x063A, .en = 'y' }, // غ
    .{ .fa = 0x0639, .en = 'u' }, // ع
    .{ .fa = 0x0647, .en = 'i' }, // ه
    .{ .fa = 0x062E, .en = 'o' }, // خ
    .{ .fa = 0x062D, .en = 'p' }, // ح
    .{ .fa = 0x062C, .en = '[' }, // ج
    .{ .fa = 0x0686, .en = ']' }, // چ
    .{ .fa = 0x067E, .en = '\\' }, // پ
    .{ .fa = 0x0634, .en = 'a' }, // ش
    .{ .fa = 0x0633, .en = 's' }, // س
    .{ .fa = 0x06CC, .en = 'd' }, // ی
    .{ .fa = 0x0628, .en = 'f' }, // ب
    .{ .fa = 0x0644, .en = 'g' }, // ل
    .{ .fa = 0x0627, .en = 'h' }, // ا
    .{ .fa = 0x062A, .en = 'j' }, // ت
    .{ .fa = 0x0646, .en = 'k' }, // ن
    .{ .fa = 0x0645, .en = 'l' }, // م
    .{ .fa = 0x06A9, .en = ';' }, // ک
    .{ .fa = 0x06AF, .en = '\'' }, // گ
    .{ .fa = 0x0638, .en = 'z' }, // ظ
    .{ .fa = 0x0637, .en = 'x' }, // ط
    .{ .fa = 0x0632, .en = 'c' }, // ز
    .{ .fa = 0x0631, .en = 'v' }, // ر
    .{ .fa = 0x0630, .en = 'b' }, // ذ
    .{ .fa = 0x062F, .en = 'n' }, // د
    .{ .fa = 0x0626, .en = 'm' }, // ئ
    .{ .fa = 0x0648, .en = ',' }, // و
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
