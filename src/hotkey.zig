const std = @import("std");
const windows = std.os.windows;
const config = @import("config.zig");

const HWND = windows.HWND;
const UINT = windows.UINT;
const BOOL = windows.BOOL;

extern "user32" fn RegisterHotKey(hWnd: ?HWND, id: i32, fsModifiers: UINT, vk: UINT) callconv(windows.WINAPI) BOOL;
extern "user32" fn UnregisterHotKey(hWnd: ?HWND, id: i32) callconv(windows.WINAPI) BOOL;

const MOD_NOREPEAT: UINT = 0x4000;

pub const HotkeyId = enum(i32) {
    convert = 1,
    convert_reverse = 2,
    convert_case = 3,
    search_google = 4,
    translate = 5,
    qr_code = 6,
};

pub fn registerHotkeys(hWnd: ?HWND, cfg: config.Config) bool {
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.convert), @intCast(cfg.hk_convert.mod | MOD_NOREPEAT), @intCast(cfg.hk_convert.vk));
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.convert_reverse), @intCast(cfg.hk_reverse.mod | MOD_NOREPEAT), @intCast(cfg.hk_reverse.vk));
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.convert_case), @intCast(cfg.hk_case.mod | MOD_NOREPEAT), @intCast(cfg.hk_case.vk));
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.search_google), @intCast(cfg.hk_search.mod | MOD_NOREPEAT), @intCast(cfg.hk_search.vk));
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.translate), @intCast(cfg.hk_translate.mod | MOD_NOREPEAT), @intCast(cfg.hk_translate.vk));
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.qr_code), @intCast(cfg.hk_qr.mod | MOD_NOREPEAT), @intCast(cfg.hk_qr.vk));
    return true;
}

pub fn unregisterHotkeys(hWnd: ?HWND) void {
    _ = UnregisterHotKey(hWnd, @intFromEnum(HotkeyId.convert));
    _ = UnregisterHotKey(hWnd, @intFromEnum(HotkeyId.convert_reverse));
    _ = UnregisterHotKey(hWnd, @intFromEnum(HotkeyId.convert_case));
    _ = UnregisterHotKey(hWnd, @intFromEnum(HotkeyId.search_google));
    _ = UnregisterHotKey(hWnd, @intFromEnum(HotkeyId.translate));
    _ = UnregisterHotKey(hWnd, @intFromEnum(HotkeyId.qr_code));
}
