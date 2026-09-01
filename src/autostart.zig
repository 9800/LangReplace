const std = @import("std");
const windows = std.os.windows;

const HKEY = ?*anyopaque;
const LSTATUS = i32;

const HKEY_CURRENT_USER: HKEY = @ptrFromInt(0x80000001);
const KEY_SET_VALUE: u32 = 0x0002;
const KEY_QUERY_VALUE: u32 = 0x0001;
const REG_SZ: u32 = 1;

extern "advapi32" fn RegOpenKeyExW(hKey: HKEY, lpSubKey: [*:0]const u16, ulOptions: u32, samDesired: u32, phkResult: *HKEY) callconv(windows.WINAPI) LSTATUS;
extern "advapi32" fn RegSetValueExW(hKey: HKEY, lpValueName: [*:0]const u16, reserved: u32, dwType: u32, lpData: [*]const u8, cbData: u32) callconv(windows.WINAPI) LSTATUS;
extern "advapi32" fn RegDeleteValueW(hKey: HKEY, lpValueName: [*:0]const u16) callconv(windows.WINAPI) LSTATUS;
extern "advapi32" fn RegQueryValueExW(hKey: HKEY, lpValueName: [*:0]const u16, lpReserved: ?*u32, lpType: ?*u32, lpData: ?[*]u8, lpcbData: ?*u32) callconv(windows.WINAPI) LSTATUS;
extern "advapi32" fn RegCloseKey(hKey: HKEY) callconv(windows.WINAPI) LSTATUS;
extern "kernel32" fn GetModuleFileNameW(h: ?windows.HMODULE, p: [*]u16, n: windows.DWORD) callconv(windows.WINAPI) windows.DWORD;

const runKeyW = std.unicode.utf8ToUtf16LeStringLiteral("Software\\Microsoft\\Windows\\CurrentVersion\\Run");
const valueNameW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplace");

fn exePathWide() ?[:0]u16 {
    var buf: [4096]u16 = undefined;
    const len = GetModuleFileNameW(null, &buf, buf.len);
    if (len == 0 or len >= buf.len) return null;
    buf[len] = 0;
    return buf[0..len :0];
}

pub fn getAutostart() bool {
    var hkey: HKEY = null;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, runKeyW, 0, KEY_QUERY_VALUE, &hkey) != 0) return false;
    defer _ = RegCloseKey(hkey);
    var size: u32 = 0;
    return RegQueryValueExW(hkey, valueNameW, null, null, null, &size) == 0;
}

pub fn setAutostart(enable: bool) void {
    var hkey: HKEY = null;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, runKeyW, 0, KEY_SET_VALUE, &hkey) != 0) return;
    defer _ = RegCloseKey(hkey);

    if (enable) {
        const path = exePathWide() orelse return;
        const bytes: [*]const u8 = @ptrCast(path.ptr);
        const cb: u32 = @intCast((path.len + 1) * 2);
        _ = RegSetValueExW(hkey, valueNameW, 0, REG_SZ, bytes, cb);
    } else {
        _ = RegDeleteValueW(hkey, valueNameW);
    }
}
