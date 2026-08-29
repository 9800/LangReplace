const std = @import("std");
const windows = std.os.windows;

const tray = @import("tray.zig");
const hotkey = @import("hotkey.zig");
const clipboard = @import("clipboard.zig");
const converter = @import("converter.zig");
const search = @import("search.zig");

const HWND = windows.HWND;
const UINT = windows.UINT;
const WPARAM = windows.WPARAM;
const LPARAM = windows.LPARAM;
const LRESULT = windows.LRESULT;
const HINSTANCE = windows.HINSTANCE;
const DWORD = windows.DWORD;
const BOOL = windows.BOOL;

const classNameW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceWindow");
const windowNameW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplace");

extern "user32" fn RegisterClassExW(wndClassEx: *const WNDCLASSEXW) callconv(windows.WINAPI) u16;
extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: windows.LPCWSTR,
    lpWindowName: windows.LPCWSTR,
    dwStyle: DWORD,
    X: i32,
    Y: i32,
    nWidth: i32,
    nHeight: i32,
    hWndParent: ?HWND,
    hMenu: ?windows.HMENU,
    hInstance: ?HINSTANCE,
    lpParam: ?*anyopaque,
) callconv(windows.WINAPI) ?HWND;
extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(windows.WINAPI) BOOL;
extern "user32" fn UpdateWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn GetMessageW(lpMsg: *windows.MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(windows.WINAPI) BOOL;
extern "user32" fn TranslateMessage(lpMsg: *const windows.MSG) callconv(windows.WINAPI) BOOL;
extern "user32" fn DispatchMessageW(lpMsg: *const windows.MSG) callconv(windows.WINAPI) LRESULT;
extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(windows.WINAPI) void;
extern "user32" fn MessageBoxA(hWnd: ?HWND, lpText: windows.LPCSTR, lpCaption: windows.LPCSTR, uType: UINT) callconv(windows.WINAPI) i32;

const WNDCLASSEXW = extern struct {
    cbSize: UINT,
    style: UINT,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(windows.WINAPI) LRESULT,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: ?HINSTANCE,
    hIcon: ?windows.HICON,
    hCursor: ?windows.HCURSOR,
    hbrBackground: ?windows.HBRUSH,
    lpszMenuName: ?windows.LPCWSTR,
    lpszClassName: windows.LPCWSTR,
    hIconSm: ?windows.HICON,
};

const WM_HOTKEY: UINT = 0x0312;
const WM_COMMAND: UINT = 0x0111;
const WM_DESTROY: UINT = 0x0002;
const SW_HIDE: i32 = 0;
const WS_OVERLAPPEDWINDOW: DWORD = 0x00CF0000;
const CW_USEDEFAULT: i32 = @as(i32, @bitCast(@as(u32, 0x80000000)));

var g_hInstance: ?HINSTANCE = null;
var g_tray: ?tray.TrayManager = null;

fn handleMenuCommand(cmd: usize, hWnd: HWND) void {
    switch (cmd) {
        tray.MENU_ID_EXIT => {
            if (g_tray) |*t| t.cleanup();
            hotkey.unregisterHotkeys(hWnd);
            PostQuitMessage(0);
        },
        tray.MENU_ID_SETTINGS => {
            _ = MessageBoxA(hWnd, "Settings window coming soon!", "LangReplace", 0x40);
        },
        tray.MENU_ID_CONVERT => handleHotkey(.convert),
        else => {},
    }
}

fn windowProc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    switch (Msg) {
        WM_HOTKEY => {
            const hotkeyId = @as(hotkey.HotkeyId, @enumFromInt(@as(i32, @intCast(wParam))));
            handleHotkey(hotkeyId);
            return 0;
        },
        WM_COMMAND => {
            handleMenuCommand(wParam & 0xFFFF, hWnd);
            return 0;
        },
        tray.WM_TRAYICON => {
            if (g_tray) |*t| {
                const x = @as(i32, @intCast(@as(i16, @truncate(lParam))));
                const y = @as(i32, @intCast(@as(i16, @truncate(lParam >> 16))));
                const cmd = t.showContextMenu(x, y);
                if (cmd != 0) handleMenuCommand(cmd, hWnd);
            }
            return 0;
        },
        WM_DESTROY => {
            if (g_tray) |*t| t.cleanup();
            hotkey.unregisterHotkeys(hWnd);
            PostQuitMessage(0);
            return 0;
        },
        else => return DefWindowProcW(hWnd, Msg, wParam, lParam),
    }
}

fn handleHotkey(id: hotkey.HotkeyId) void {
    const allocator = std.heap.page_allocator;

    const text = clipboard.getClipboardText(allocator) catch return;
    if (text) |t| {
        defer allocator.free(t);

        switch (id) {
            .convert => {
                const converted = converter.convertText(t, .english, .persian, allocator) catch return;
                defer allocator.free(converted);
                _ = clipboard.setClipboardText(converted);
            },
            .convert_reverse => {
                const converted = converter.convertText(t, .persian, .english, allocator) catch return;
                defer allocator.free(converted);
                _ = clipboard.setClipboardText(converted);
            },
            .convert_case => {
                const converted = converter.convertTextPreserveCase(t, .english, .persian, allocator) catch return;
                defer allocator.free(converted);
                _ = clipboard.setClipboardText(converted);
            },
            .search_google => {
                _ = search.openGoogleSearch(t, allocator);
            },
            .translate => {},
            .qr_code => {},
        }
    }
}

pub fn main() !void {
    const hModule = windows.kernel32.GetModuleHandleW(null);
    g_hInstance = @ptrCast(hModule);

    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = 0,
        .lpfnWndProc = windowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = g_hInstance,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = classNameW,
        .hIconSm = null,
    };

    _ = RegisterClassExW(&wc);

    const hWnd = CreateWindowExW(
        0,
        classNameW,
        windowNameW,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        null,
        null,
        g_hInstance,
        null,
    ) orelse return error.WindowCreationFailed;

    g_tray = try tray.TrayManager.init(hWnd);
    _ = hotkey.registerHotkeys(hWnd);

    _ = ShowWindow(hWnd, SW_HIDE);
    _ = UpdateWindow(hWnd);

    var msg: windows.MSG = undefined;
    while (GetMessageW(&msg, null, 0, 0) != 0) {
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
}
