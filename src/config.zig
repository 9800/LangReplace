const std = @import("std");
const windows = std.os.windows;

const DWORD = windows.DWORD;

pub const MOD_ALT: u32 = 0x0001;
pub const MOD_CONTROL: u32 = 0x0002;
pub const MOD_SHIFT: u32 = 0x0004;

pub const Hotkey = struct { mod: u32 = 0, vk: u32 = 0 };

pub const Config = struct {
    language: u32 = 0, // 0=English, 1=Persian
    autostart: bool = false,
    ignore_upper_case: bool = true,
    ignore_english: bool = true,
    enable_middle_mouse: bool = false,
    hk_convert: Hotkey = .{ .mod = 0, .vk = 0x79 },
    hk_reverse: Hotkey = .{ .mod = 0, .vk = 0x75 },
    hk_case: Hotkey = .{ .mod = MOD_SHIFT, .vk = 0x79 },
    hk_search: Hotkey = .{ .mod = MOD_CONTROL, .vk = 0x47 },
    hk_translate: Hotkey = .{ .mod = MOD_CONTROL, .vk = 0x54 },
    hk_qr: Hotkey = .{ .mod = MOD_CONTROL, .vk = 0x4D },
};

pub var g_config: Config = .{};

extern "kernel32" fn GetModuleFileNameW(h: ?windows.HMODULE, p: [*]u16, n: DWORD) callconv(windows.WINAPI) DWORD;

fn cfgPath(allocator: std.mem.Allocator) []const u8 {
    var buf: [4096]u16 = undefined;
    const len = GetModuleFileNameW(null, &buf, buf.len);
    if (len == 0 or len >= buf.len) return "langreplace.cfg";

    var last: usize = 0;
    var i: usize = 0;
    while (i < len) : (i += 1) {
        if (buf[i] == '\\' or buf[i] == '/') last = i;
    }
    if (last == 0) return "langreplace.cfg";

    const dirU8 = std.unicode.utf16LeToUtf8Alloc(allocator, buf[0..last]) catch return "langreplace.cfg";
    defer allocator.free(dirU8);
    return std.fmt.allocPrint(allocator, "{s}\\langreplace.cfg", .{dirU8}) catch "langreplace.cfg";
}

pub fn fileExists() bool {
    const allocator = std.heap.page_allocator;
    const p = cfgPath(allocator);
    std.fs.cwd().access(p, .{}) catch return false;
    return true;
}

fn boolStr(b: bool) []const u8 {
    return if (b) "1" else "0";
}

pub fn save(cfg: Config, allocator: std.mem.Allocator) void {
    const p = cfgPath(allocator);
    const s = std.fmt.allocPrint(allocator,
        \\language={d}
        \\autostart={s}
        \\ignore_upper_case={s}
        \\ignore_english={s}
        \\enable_middle_mouse={s}
        \\hk_convert={d},{d}
        \\hk_reverse={d},{d}
        \\hk_case={d},{d}
        \\hk_search={d},{d}
        \\hk_translate={d},{d}
        \\hk_qr={d},{d}
        \\
    , .{
        cfg.language,
        boolStr(cfg.autostart),
        boolStr(cfg.ignore_upper_case), boolStr(cfg.ignore_english), boolStr(cfg.enable_middle_mouse),
        cfg.hk_convert.mod,  cfg.hk_convert.vk,
        cfg.hk_reverse.mod,  cfg.hk_reverse.vk,
        cfg.hk_case.mod,     cfg.hk_case.vk,
        cfg.hk_search.mod,   cfg.hk_search.vk,
        cfg.hk_translate.mod, cfg.hk_translate.vk,
        cfg.hk_qr.mod,       cfg.hk_qr.vk,
    }) catch return;
    defer allocator.free(s);
    var f = std.fs.cwd().createFile(p, .{}) catch return;
    defer f.close();
    f.writeAll(s) catch return;
}

fn parseHotkey(line: []const u8) Hotkey {
    var it = std.mem.splitScalar(u8, line, ',');
    const m = it.next() orelse return .{};
    const v = it.next() orelse return .{};
    return Hotkey{
        .mod = std.fmt.parseInt(u32, m, 10) catch 0,
        .vk = std.fmt.parseInt(u32, v, 10) catch 0,
    };
}

pub fn load(allocator: std.mem.Allocator) Config {
    var cfg = Config{};
    const p = cfgPath(allocator);
    const content = std.fs.cwd().readFileAlloc(allocator, p, 100000) catch return cfg;
    defer allocator.free(content);

    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |raw| {
        const line = std.mem.trim(u8, raw, "\r \t");
        if (std.mem.startsWith(u8, line, "language=")) {
            cfg.language = std.fmt.parseInt(u32, line["language=".len..], 10) catch 0;
        } else if (std.mem.startsWith(u8, line, "autostart=")) {
            cfg.autostart = !std.mem.endsWith(u8, line, "=0");
        } else if (std.mem.startsWith(u8, line, "ignore_upper_case=")) {
            cfg.ignore_upper_case = !std.mem.endsWith(u8, line, "=0");
        } else if (std.mem.startsWith(u8, line, "ignore_english=")) {
            cfg.ignore_english = !std.mem.endsWith(u8, line, "=0");
        } else if (std.mem.startsWith(u8, line, "enable_middle_mouse=")) {
            cfg.enable_middle_mouse = !std.mem.endsWith(u8, line, "=0");
        } else if (std.mem.startsWith(u8, line, "hk_convert=")) {
            cfg.hk_convert = parseHotkey(line["hk_convert=".len..]);
        } else if (std.mem.startsWith(u8, line, "hk_reverse=")) {
            cfg.hk_reverse = parseHotkey(line["hk_reverse=".len..]);
        } else if (std.mem.startsWith(u8, line, "hk_case=")) {
            cfg.hk_case = parseHotkey(line["hk_case=".len..]);
        } else if (std.mem.startsWith(u8, line, "hk_search=")) {
            cfg.hk_search = parseHotkey(line["hk_search=".len..]);
        } else if (std.mem.startsWith(u8, line, "hk_translate=")) {
            cfg.hk_translate = parseHotkey(line["hk_translate=".len..]);
        } else if (std.mem.startsWith(u8, line, "hk_qr=")) {
            cfg.hk_qr = parseHotkey(line["hk_qr=".len..]);
        }
    }
    return cfg;
}

fn vkName(vk: u32) []const u8 {
    if (vk >= 0x70 and vk <= 0x7B) {
        const names = [_][]const u8{ "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12" };
        return names[vk - 0x70];
    }
    return "Key";
}

pub fn hotkeyLabel(cfg: Hotkey, allocator: std.mem.Allocator) []u8 {
    var parts = std.ArrayList(u8).init(allocator);
    if (cfg.mod & MOD_CONTROL != 0) parts.appendSlice("Ctrl+") catch return @constCast("");
    if (cfg.mod & MOD_SHIFT != 0) parts.appendSlice("Shift+") catch return @constCast("");
    if (cfg.mod & MOD_ALT != 0) parts.appendSlice("Alt+") catch return @constCast("");

    // ✅ اصلاح: cfg.vk
    if (cfg.vk >= 0x70 and cfg.vk <= 0x7B) {
        parts.appendSlice(vkName(cfg.vk)) catch return @constCast("");
    } else if (cfg.vk >= 0x41 and cfg.vk <= 0x5A) {
        parts.append(@intCast('A' + (cfg.vk - 0x41))) catch return @constCast("");
    } else if (cfg.vk >= 0x30 and cfg.vk <= 0x39) {
        parts.append(@intCast('0' + (cfg.vk - 0x30))) catch return @constCast("");
    } else {
        parts.appendSlice("Key") catch return @constCast("");
    }
    return parts.toOwnedSlice() catch return @constCast("");
}
