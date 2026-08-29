const std = @import("std");

pub fn getGoogleSearchUrl(text: []const u8) []const u8 {
    _ = text;
    return "https://www.google.com/search?q=";
}

pub fn openUrl(url: []const u8) bool {
    const windows = std.os.windows;
    
    const ShellExecuteA = extern "shell32" fn (
        hwnd: ?windows.HWND,
        lpOperation: windows.LPCSTR,
        lpFile: windows.LPCSTR,
        lpParameters: windows.LPCSTR,
        lpDirectory: windows.LPCSTR,
        nShowCmd: i32,
    ) callconv(windows.WINAPI) windows.HINSTANCE;
    
    const result = ShellExecuteA(null, "open", url, null, null, 1);
    return @intFromPtr(result) > 32;
}
