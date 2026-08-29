const std = @import("std");
const windows = std.os.windows;

// ✅ extern باید در سطح ماژول باشه، نه داخل تابع
extern "shell32" fn ShellExecuteA(
    hwnd: ?windows.HWND,
    lpOperation: windows.LPCSTR,
    lpFile: windows.LPCSTR,
    lpParameters: windows.LPCSTR,
    lpDirectory: windows.LPCSTR,
    nShowCmd: i32,
) callconv(windows.WINAPI) windows.HINSTANCE;

pub fn getGoogleSearchUrl(text: []const u8) []const u8 {
    _ = text;
    return "https://www.google.com/search?q=";
}

pub fn openUrl(url: []const u8) bool {
    const result = ShellExecuteA(null, "open", url, null, null, 1);
    return @intFromPtr(result) > 32;
}
