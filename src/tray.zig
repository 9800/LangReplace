const std = @import("std");
const windows = std.os.windows;

const HWND = windows.HWND;
const UINT = windows.UINT;
const DWORD = windows.DWORD;
const HICON = windows.HICON;
const BOOL = windows.BOOL;
const UINT_PTR = usize;

extern "shell32" fn Shell_NotifyIconW(dwMessage: DWORD, lpData: *NOTIFYICONDATAW) callconv(windows.WINAPI) BOOL;
extern "user32" fn LoadIconW(hInstance: ?windows.HINSTANCE, lpIconName: windows.LPCWSTR) callconv(windows.WINAPI) ?HICON;
extern "user32" fn CreatePopupMenu() callconv(windows.WINAPI) ?windows.HMENU;
extern "user32" fn AppendMenuA(hMenu: windows.HMENU, uFlags: UINT, uIDNewItem: UINT_PTR, lpNewItem: windows.LPCSTR) callconv(windows.WINAPI) BOOL;
extern "user32" fn TrackPopupMenu(hMenu: windows.HMENU, uFlags: UINT, x: i32, y: i32, nReserved: i32, hWnd: HWND, prcRect: ?*const windows.RECT) callconv(windows.WINAPI) BOOL;
extern "user32" fn DestroyMenu(hMenu: windows.HMENU) callconv(windows.WINAPI) BOOL;
extern "user32" fn SetForegroundWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;

const NIM_ADD: DWORD = 0;
const NIM_MODIFY: DWORD = 1;
const NIM_DELETE: DWORD = 2;
const NIF_MESSAGE: UINT = 1;
const NIF_ICON: UINT = 2;
const NIF_TIP: UINT = 4;
const NIF_INFO: UINT = 0x10;
const NIIF_INFO: DWORD = 1;
const WM_USER: UINT = 0x0400;
pub const WM_TRAYICON: UINT = WM_USER + 1;
const MF_STRING: UINT = 0;
const TPM_RIGHTBUTTON: UINT = 0x0002;
const TPM_RETURNCMD: UINT = 0x0080;

pub const MENU_ID_SETTINGS: UINT_PTR = 1001;
pub const MENU_ID_CONVERT: UINT_PTR = 1002;
pub const MENU_ID_EXIT: UINT_PTR = 1003;

const GUID = extern struct { a: u32, b: u16, c: u16, d: [8]u8 };

const NOTIFYICONDATAW = extern struct {
    cbSize: DWORD,
    hWnd: HWND,
    uID: UINT,
    uFlags: UINT,
    uCallbackMessage: UINT,
    hIcon: ?HICON,
    szTip: [64]u16,
    dwState: DWORD,
    dwStateMask: DWORD,
    szInfo: [256]u16,
    uTimeout: DWORD,
    szInfoTitle: [64]u16,
    dwInfoFlags: DWORD,
    guidItem: GUID,
    hBalloonIcon: ?HICON,
};

const tipW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplace");

pub const TrayManager = struct {
    hWnd: HWND,
    nid: NOTIFYICONDATAW,

    pub fn init(hWnd: HWND) !TrayManager {
        var nid: NOTIFYICONDATAW = undefined;
        const bytes: [*]u8 = @ptrCast(&nid);
        @memset(bytes[0..@sizeOf(NOTIFYICONDATAW)], 0);

        nid.cbSize = @sizeOf(NOTIFYICONDATAW);
        nid.hWnd = hWnd;
        nid.uID = 1;
        nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
        nid.uCallbackMessage = WM_TRAYICON;
        nid.hIcon = LoadIconW(null, @as(windows.LPCWSTR, @ptrFromInt(32512)));
        @memcpy(nid.szTip[0..tipW.len], tipW);

        if (Shell_NotifyIconW(NIM_ADD, &nid) == 0) return error.TrayIconFailed;
        return TrayManager{ .hWnd = hWnd, .nid = nid };
    }

    // ✅ حباب اعلان (بالون) با متن فارسی
    pub fn showBalloon(self: *TrayManager, title: []const u8, msg: []const u8) void {
        var nid = self.nid;
        nid.uFlags = NIF_INFO;
        nid.dwInfoFlags = NIIF_INFO;
        nid.uTimeout = 2000;
        @memset(&nid.szInfo, 0);
        @memset(&nid.szInfoTitle, 0);
        _ = std.unicode.utf8ToUtf16LeSlice(&nid.szInfoTitle, title) catch 0;
        _ = std.unicode.utf8ToUtf16LeSlice(&nid.szInfo, msg) catch 0;
        _ = Shell_NotifyIconW(NIM_MODIFY, &nid);
    }

    pub fn showContextMenu(self: *TrayManager, x: i32, y: i32) UINT_PTR {
        const hMenu = CreatePopupMenu() orelse return 0;
        defer _ = DestroyMenu(hMenu);

        _ = AppendMenuA(hMenu, MF_STRING, MENU_ID_SETTINGS, "Settings...");
        _ = AppendMenuA(hMenu, MF_STRING, MENU_ID_CONVERT, "Convert (F10)");
        _ = AppendMenuA(hMenu, MF_STRING, MENU_ID_EXIT, "Exit");

        _ = SetForegroundWindow(self.hWnd);
        const cmd = TrackPopupMenu(hMenu, TPM_RIGHTBUTTON | TPM_RETURNCMD, x, y, 0, self.hWnd, null);
        if (cmd <= 0) return 0;
        return @intCast(cmd);
    }

    pub fn cleanup(self: *TrayManager) void {
        _ = Shell_NotifyIconW(NIM_DELETE, &self.nid);
    }
};
