const std = @import("std");
const windows = std.os.windows;

const HWND = windows.HWND;
const UINT = windows.UINT;
const DWORD = windows.DWORD;
const HICON = windows.HICON;
const BOOL = windows.BOOL;
const UINT_PTR = usize;

extern "shell32" fn Shell_NotifyIconA(dwMessage: DWORD, lpData: *NOTIFYICONDATAA) callconv(windows.WINAPI) BOOL;
extern "user32" fn LoadIconA(hInstance: ?windows.HINSTANCE, lpIconName: windows.LPCSTR) callconv(windows.WINAPI) ?HICON;
extern "user32" fn CreatePopupMenu() callconv(windows.WINAPI) ?windows.HMENU;
extern "user32" fn AppendMenuA(hMenu: windows.HMENU, uFlags: UINT, uIDNewItem: UINT_PTR, lpNewItem: windows.LPCSTR) callconv(windows.WINAPI) BOOL;
extern "user32" fn TrackPopupMenu(hMenu: windows.HMENU, uFlags: UINT, x: i32, y: i32, nReserved: i32, hWnd: HWND, prcRect: ?*const windows.RECT) callconv(windows.WINAPI) BOOL;
extern "user32" fn DestroyMenu(hMenu: windows.HMENU) callconv(windows.WINAPI) BOOL;
extern "user32" fn SetForegroundWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;

const NIM_ADD: DWORD = 0x00000000;
const NIM_DELETE: DWORD = 0x00000002;
const NIF_MESSAGE: UINT = 0x00000001;
const NIF_ICON: UINT = 0x00000002;
const NIF_TIP: UINT = 0x00000004;
const WM_USER: UINT = 0x0400;
pub const WM_TRAYICON: UINT = WM_USER + 1;
const MF_STRING: UINT = 0x00000000;
const TPM_RIGHTBUTTON: UINT = 0x0002;
const TPM_RETURNCMD: UINT = 0x0080;

pub const MENU_ID_SETTINGS: UINT_PTR = 1001;
pub const MENU_ID_CONVERT: UINT_PTR = 1002;
pub const MENU_ID_EXIT: UINT_PTR = 1003;

const NOTIFYICONDATAA = extern struct {
    cbSize: DWORD,
    hWnd: HWND,
    uID: UINT,
    uFlags: UINT,
    uCallbackMessage: UINT,
    hIcon: ?HICON,
    szTip: [64]u8,
};

pub const TrayManager = struct {
    hWnd: HWND,
    nid: NOTIFYICONDATAA,

    pub fn init(hWnd: HWND) !TrayManager {
        var nid: NOTIFYICONDATAA = undefined;
        nid.cbSize = @sizeOf(NOTIFYICONDATAA);
        nid.hWnd = hWnd;
        nid.uID = 1;
        nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
        nid.uCallbackMessage = WM_TRAYICON;
        // آیکون پیش‌فرض ویندوز (IDI_APPLICATION = 32512)
        nid.hIcon = LoadIconA(null, @as(windows.LPCSTR, @ptrFromInt(32512)));
        @memset(&nid.szTip, 0);
        const tip = "LangReplace";
        @memcpy(nid.szTip[0..tip.len], tip);

        if (Shell_NotifyIconA(NIM_ADD, &nid) == 0) {
            return error.TrayIconFailed;
        }

        return TrayManager{
            .hWnd = hWnd,
            .nid = nid,
        };
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
        _ = Shell_NotifyIconA(NIM_DELETE, &self.nid);
    }
};
