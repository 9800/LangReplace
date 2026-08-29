const std = @import("std");
const windows = std.os.windows;

const HWND = windows.HWND;
const UINT = windows.UINT;
const WPARAM = windows.WPARAM;
const LPARAM = windows.LPARAM;
const LRESULT = windows.LRESULT;
const DWORD = windows.DWORD;

extern "user32" fn RegisterHotKey(hWnd: ?HWND, id: i32, fsModifiers: UINT, vk: UINT) callconv(windows.WINAPI) BOOL;
extern "user32" fn UnregisterHotKey(hWnd: ?HWND, id: i32) callconv(windows.WINAPI) BOOL;
extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(windows.WINAPI) void;

const BOOL = windows.BOOL;
const MOD_CONTROL = 0x0002;
const MOD_SHIFT = 0x0004;

pub const HotkeyId = enum(i32) {
    convert = 1,
    convert_reverse = 2,
    convert_case = 3,
    search_google = 4,
    translate = 5,
    qr_code = 6,
};

pub fn registerHotkeys(hWnd: ?HWND) bool {
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.convert), 0, 0x79); // F10
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.convert_reverse), 0, 0x75); // F6
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.convert_case), MOD_SHIFT, 0x79); // Shift+F10
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.search_google), MOD_CONTROL, 0x47); // Ctrl+G
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.translate), MOD_CONTROL, 0x54); // Ctrl+T
    _ = RegisterHotKey(hWnd, @intFromEnum(HotkeyId.qr_code), MOD_CONTROL, 0x4D); // Ctrl+M
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
