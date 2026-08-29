const std = @import("std");

pub const KeyboardLayout = enum {
    persian,
    english,
};

const CharMap = struct {
    from: u8,
    to: u8,
};

// نقشه تبدیل فارسی به انگلیسی (چیدمان استاندارد)
const fa_to_en_map = [_]CharMap{
    .{ .from = 'ض', .to = 'q' },
    .{ .from = 'ص', .to = 'w' },
    .{ .from = 'ث', .to = 'e' },
    .{ .from = 'ق', .to = 'r' },
    .{ .from = 'ف', .to = 't' },
    .{ .from = 'غ', .to = 'y' },
    .{ .from = 'ع', .to = 'u' },
    .{ .from = 'ه', .to = 'i' },
    .{ .from = 'خ', .to = 'o' },
    .{ .from = 'ح', .to = 'p' },
    .{ .from = 'ج', .to = '[' },
    .{ .from = 'چ', .to = ']' },
    .{ .from = 'پ', .to = '\\' },
    .{ .from = 'ش', .to = 'a' },
    .{ .from = 'س', .to = 's' },
    .{ .from = 'ی', .to = 'd' },
    .{ .from = 'ب', .to = 'f' },
    .{ .from = 'ل', .to = 'g' },
    .{ .from = 'ا', .to = 'h' },
    .{ .from = 'ت', .to = 'j' },
    .{ .from = 'ن', .to = 'k' },
    .{ .from = 'م', .to = 'l' },
    .{ .from = 'ک', .to = ';' },
    .{ .from = 'گ', .to = '\'' },
    .{ .from = 'ظ', .to = 'z' },
    .{ .from = 'ط', .to = 'x' },
    .{ .from = 'ز', .to = 'c' },
    .{ .from = 'ر', .to = 'v' },
    .{ .from = 'ذ', .to = 'b' },
    .{ .from = 'د', .to = 'n' },
    .{ .from = 'ئ', .to = 'm' },
    .{ .from = 'و', .to = ',' },
    .{ .from = '.', .to = '.' },
    .{ .from = '/', .to = '/' },
};

const en_to_fa_map = [_]CharMap{
    .{ .from = 'q', .to = 'ض' },
    .{ .from = 'w', .to = 'ص' },
    .{ .from = 'e', .to = 'ث' },
    .{ .from = 'r', .to = 'ق' },
    .{ .from = 't', .to = 'ف' },
    .{ .from = 'y', .to = 'غ' },
    .{ .from = 'u', .to = 'ع' },
    .{ .from = 'i', .to = 'ه' },
    .{ .from = 'o', .to = 'خ' },
    .{ .from = 'p', .to = 'ح' },
    .{ .from = '[', .to = 'ج' },
    .{ .from = ']', .to = 'چ' },
    .{ .from = '\\', .to = 'پ' },
    .{ .from = 'a', .to = 'ش' },
    .{ .from = 's', .to = 'س' },
    .{ .from = 'd', .to = 'ی' },
    .{ .from = 'f', .to = 'ب' },
    .{ .from = 'g', .to = 'ل' },
    .{ .from = 'h', .to = 'ا' },
    .{ .from = 'j', .to = 'ت' },
    .{ .from = 'k', .to = 'ن' },
    .{ .from = 'l', .to = 'م' },
    .{ .from = ';', .to = 'ک' },
    .{ .from = '\'', .to = 'گ' },
    .{ .from = 'z', .to = 'ظ' },
    .{ .from = 'x', .to = 'ط' },
    .{ .from = 'c', .to = 'ز' },
    .{ .from = 'v', .to = 'ر' },
    .{ .from = 'b', .to = 'ذ' },
    .{ .from = 'n', .to = 'د' },
    .{ .from = 'm', .to = 'ئ' },
    .{ .from = ',', .to = 'و' },
};

pub fn convertText(text: []const u8, from: KeyboardLayout, to: KeyboardLayout, allocator: std.mem.Allocator) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    const map = if (from == .persian and to == .english) fa_to_en_map else en_to_fa_map;

    var i: usize = 0;
    while (i < text.len) {
        const byte = text[i];
        var found = false;

        for (map) |entry| {
            if (entry.from == byte) {
                try result.append(entry.to);
                found = true;
                break;
            }
        }

        if (!found) {
            try result.append(byte);
        }

        i += 1;
    }

    return try result.toOwnedSlice();
}

pub fn convertTextPreserveCase(text: []const u8, from: KeyboardLayout, to: KeyboardLayout, allocator: std.mem.Allocator) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    const map = if (from == .persian and to == .english) fa_to_en_map else en_to_fa_map;

    var i: usize = 0;
    while (i < text.len) {
        const byte = text[i];
        var found = false;

        for (map) |entry| {
            if (entry.from == byte or std.ascii.toLower(entry.from) == std.ascii.toLower(byte)) {
                var converted = entry.to;
                if (std.ascii.isUpper(byte)) {
                    converted = std.ascii.toUpper(converted);
                }
                try result.append(converted);
                found = true;
                break;
            }
        }

        if (!found) {
            try result.append(byte);
        }

        i += 1;
    }

    return try result.toOwnedSlice();
}
