const std = @import("std");
const windows = std.os.windows;

const HWND = windows.HWND;
const UINT = windows.UINT;
const WPARAM = windows.WPARAM;
const LPARAM = windows.LPARAM;
const LRESULT = windows.LRESULT;
const HINSTANCE = windows.HINSTANCE;
const LPCWSTR = windows.LPCWSTR;
const DWORD = windows.DWORD;

extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: LPCWSTR,
    lpWindowName: LPCWSTR,
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

const BOOL = windows.BOOL;
const WS_OVERLAPPEDWINDOW = 0x00CF0000;
const SW_SHOW = 5;
const WM_DESTROY = 0x0002;
const CW_USEDEFAULT = @as(i32, @bitCast(@as(u32, 0x80000000)));

const WNDCLASSEXW = extern struct {
    cbSize: UINT,
    style: UINT,
    lpfnWndProc: *const fn(HWND, UINT, WPARAM, LPARAM) callconv(windows.WINAPI) LRESULT,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: ?HINSTANCE,
    hIcon: ?windows.HICON,
    hCursor: ?windows.HCURSOR,
    hbrBackground: ?windows.HBRUSH,
    lpszMenuName: ?LPCWSTR,
    lpszClassName: LPCWSTR,
    hIconSm: ?windows.HICON,
};

var settingsWnd: ?HWND = null;

pub fn createSettingsWindow(hInstance: ?HINSTANCE) !?HWND {
    const className = "LangReplaceSettings";
    const windowName = "LangReplace Settings";

    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = 0,
        .lpfnWndProc = settingsWindowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = className,
        .hIconSm = null,
    };

    // RegisterClassExW را باید اضافه کنیم
    // برای سادگی، فعلاً این بخش را skip می‌کنیم

    const hWnd = CreateWindowExW(
        0,
        className,
        windowName,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        400,
        300,
        null,
        null,
        hInstance,
        null,
    );

    if (hWnd) |hwnd| {
        _ = ShowWindow(hwnd, SW_SHOW);
        _ = UpdateWindow(hwnd);
        settingsWnd = hwnd;
    }

    return hWnd;
}

fn settingsWindowProc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    switch (Msg) {
        WM_DESTROY => {
            PostQuitMessage(0);
            return 0;
        },
        else => {
            return DefWindowProcW(hWnd, Msg, wParam, lParam);
        },
    }
}
