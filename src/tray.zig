const std = @import("std");
const windows = std.os.windows;

const HWND = windows.HWND;
const UINT = windows.UINT;
const WPARAM = windows.WPARAM;
const LPARAM = windows.LPARAM;
const LRESULT = windows.LRESULT;
const DWORD = windows.DWORD;
const HICON = windows.HICON;

extern "shell32" fn Shell_NotifyIconA(dwMessage: DWORD, lpData: *NOTIFYICONDATAA) callconv(windows.WINAPI) BOOL;
extern "user32" fn LoadIconA(hInstance: ?windows.HINSTANCE, lpIconName: windows.LPCSTR) callconv(windows.WINAPI) ?HICON;
extern "user32" fn CreatePopupMenu() callconv(windows.WINAPI) ?windows.HMENU;
extern "user32" fn AppendMenuA(hMenu: windows.HMENU, uFlags: UINT, uIDNewItem: UINT_PTR, lpNewItem: windows.LPCSTR) callconv(windows.WINAPI) BOOL;
extern "user32" fn TrackPopupMenu(hMenu: windows.HMENU, uFlags: UINT, x: i32, y: i32, nReserved: i32, hWnd: HWND, prcRect: ?*const windows.RECT) callconv(windows.WINAPI) BOOL;
extern "user32" fn DestroyMenu(hMenu: windows.HMENU) callconv(windows.WINAPI) BOOL;
extern "user32" fn PostMessageA(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) BOOL;

const BOOL = windows.BOOL;
const NIM_ADD = 0x00000000;
const NIM_MODIFY = 0x00000001;
const NIM_DELETE = 0x00000002;
const NIF_MESSAGE = 0x00000001;
const NIF_ICON = 0x00000002;
const NIF_TIP = 0x00000004;
const WM_USER = 0x0400;
const WM_TRAYICON = WM_USER + 1;
const WM_COMMAND = 0x0111;
const WM_RBUTTONUP = 0x0205;
const MF_STRING = 0x00000000;
const TPM_RIGHTBUTTON = 0x0002;
const UINT_PTR = windows.UINT_PTR;

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
        nid.hIcon = LoadIconA(null, "IDI_APPLICATION");
        @memset(&nid.szTip, 0);
        const tip = "LangReplace";
        @memcpy(nid.szTip[0..tip.len], tip);

        if (!Shell_NotifyIconA(NIM_ADD, &nid)) {
            return error.TrayIconFailed;
        }

        return TrayManager{
            .hWnd = hWnd,
            .nid = nid,
        };
    }

    pub fn showContextMenu(self: *TrayManager, x: i32, y: i32) void {
        const hMenu = CreatePopupMenu() orelse return;
        defer _ = DestroyMenu(hMenu);

        _ = AppendMenuA(hMenu, MF_STRING, 1001, "Settings");
        _ = AppendMenuA(hMenu, MF_STRING, 1002, "Convert (F10)");
        _ = AppendMenuA(hMenu, MF_STRING, 1003, "Exit");

        _ = TrackPopupMenu(hMenu, TPM_RIGHTBUTTON, x, y, 0, self.hWnd, null);
    }

    pub fn cleanup(self: *TrayManager) void {
        _ = Shell_NotifyIconA(NIM_DELETE, &self.nid);
    }
};
