const std = @import("std");
const windows = std.os.windows;

extern "shell32" fn ShellExecuteA(
    hwnd: ?windows.HWND,
    lpOperation: ?windows.LPCSTR,
    lpFile: windows.LPCSTR,
    lpParameters: ?windows.LPCSTR,   // ✅ nullable
    lpDirectory: ?windows.LPCSTR,    // ✅ nullable
    nShowCmd: i32,
) callconv(windows.WINAPI) usize;

pub fn openUrl(url: []const u8, allocator: std.mem.Allocator) bool {
    const z = allocator.dupeZ(u8, url) catch return false;
    defer allocator.free(z);
    const result = ShellExecuteA(null, "open", z, null, null, 1);
    return result > 32;
}

pub fn openGoogleSearch(text: []const u8, allocator: std.mem.Allocator) bool {
    const url = std.fmt.allocPrint(allocator, "https://www.google.com/search?q={s}", .{text}) catch return false;
    defer allocator.free(url);
    return openUrl(url, allocator);
}
