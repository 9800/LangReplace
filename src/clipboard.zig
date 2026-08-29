const std = @import("std");
const windows = std.os.windows;

const HWND = windows.HWND;
const HANDLE = windows.HANDLE;
const UINT = windows.UINT;
const DWORD = windows.DWORD;
const LPCWSTR = windows.LPCWSTR;
const HGLOBAL = windows.HGLOBAL;
const SIZE_T = windows.SIZE_T;

extern "user32" fn OpenClipboard(hWndNewOwner: ?HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn CloseClipboard() callconv(windows.WINAPI) BOOL;
extern "user32" fn GetClipboardData(uFormat: UINT) callconv(windows.WINAPI) ?HANDLE;
extern "user32" fn SetClipboardData(uFormat: UINT, hMem: ?HANDLE) callconv(windows.WINAPI) ?HANDLE;
extern "user32" fn EmptyClipboard() callconv(windows.WINAPI) BOOL;

extern "kernel32" fn GlobalAlloc(uFlags: UINT, dwBytes: SIZE_T) callconv(windows.WINAPI) ?HGLOBAL;
extern "kernel32" fn GlobalLock(hMem: HGLOBAL) callconv(windows.WINAPI) ?*anyopaque;
extern "kernel32" fn GlobalUnlock(hMem: HGLOBAL) callconv(windows.WINAPI) BOOL;

const BOOL = windows.BOOL;
const GMEM_MOVEABLE = 0x0002;
const CF_UNICODETEXT = 13;

pub fn getClipboardText(allocator: std.mem.Allocator) !?[]u8 {
    if (!OpenClipboard(null)) {
        return null;
    }
    defer _ = CloseClipboard();

    const hData = GetClipboardData(CF_UNICODETEXT) orelse return null;
    const pData = GlobalLock(hData) orelse return null;
    defer _ = GlobalUnlock(hData);

    const wideText: [*]const u16 = @ptrCast(@alignCast(pData));
    var len: usize = 0;
    while (wideText[len] != 0) {
        len += 1;
    }

    const utf8Len = std.unicode.utf16LeToUtf8Alloc(allocator, wideText[0..len]) catch return null;
    return utf8Len;
}

pub fn setClipboardText(text: []const u8) bool {
    const wideText = std.unicode.utf8ToUtf16LeAlloc(std.heap.page_allocator, text) catch return false;
    defer std.heap.page_allocator.free(wideText);

    if (!OpenClipboard(null)) {
        return false;
    }
    defer _ = CloseClipboard();

    _ = EmptyClipboard();

    const bytesNeeded = (wideText.len + 1) * 2;
    const hMem = GlobalAlloc(GMEM_MOVEABLE, bytesNeeded) orelse return false;
    const pData = GlobalLock(hMem) orelse return false;

    const dest: [*]u16 = @ptrCast(@alignCast(pData));
    @memcpy(dest[0..wideText.len], wideText);
    dest[wideText.len] = 0;

    _ = GlobalUnlock(hMem);

    _ = SetClipboardData(CF_UNICODETEXT, hMem);
    return true;
}
