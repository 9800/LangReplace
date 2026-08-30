const std = @import("std");
const windows = std.os.windows;
const config = @import("config.zig");

const HWND = windows.HWND;
const UINT = windows.UINT;
const WPARAM = windows.WPARAM;
const LPARAM = windows.LPARAM;
const LRESULT = windows.LRESULT;
const HINSTANCE = windows.HINSTANCE;
const BOOL = windows.BOOL;

const BTN_CHANGE_BASE: usize = 2101;
const ID_CHK_UPPER: usize = 2001;
const ID_CHK_ENG: usize = 2002;
const ID_CHK_MOUSE: usize = 2003;
const ID_OK: usize = 2301;

const WS_CHILD: windows.DWORD = 0x40000000;
const WS_VISIBLE: windows.DWORD = 0x10000000;
const BS_CHECKBOX: windows.DWORD = 0x3;
const BS_PUSHBUTTON: windows.DWORD = 0x0;
const WM_CLOSE: UINT = 0x0010;
const WM_COMMAND: UINT = 0x0111;
const BM_GETCHECK: UINT = 0x00F0;
const BM_SETCHECK: UINT = 0x00F1;
const SW_SHOW: i32 = 5;

extern "user32" fn RegisterClassExW(w: *const WNDCLASSEXW) callconv(windows.WINAPI) u16;
extern "user32" fn CreateWindowExW(a: windows.DWORD, b: windows.LPCWSTR, c: windows.LPCWSTR, d: windows.DWORD, e: i32, f: i32, g: i32, h: i32, i: ?HWND, j: ?windows.HMENU, k: ?HINSTANCE, l: ?*anyopaque) callconv(windows.WINAPI) ?HWND;
extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, w: WPARAM, l: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn ShowWindow(hWnd: HWND, n: i32) callconv(windows.WINAPI) BOOL;
extern "user32" fn UpdateWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn DestroyWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn SendMessageW(hWnd: HWND, Msg: UINT, w: WPARAM, l: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn SetWindowTextW(hWnd: HWND, s: [*:0]const u16) callconv(windows.WINAPI) BOOL;
extern "user32" fn GetAsyncKeyState(v: i32) callconv(windows.WINAPI) i16;

const WNDCLASSEXW = extern struct {
    cbSize: UINT, style: UINT,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(windows.WINAPI) LRESULT,
    cbClsExtra: i32, cbWndExtra: i32, hInstance: ?HINSTANCE,
    hIcon: ?windows.HICON, hCursor: ?windows.HCURSOR, hbrBackground: ?windows.HBRUSH,
    lpszMenuName: ?windows.LPCWSTR, lpszClassName: windows.LPCWSTR, hIconSm: ?windows.HICON,
};

const clsW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceSettings");
const titleW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplace - Settings");
const btnClsW = std.unicode.utf8ToUtf16LeStringLiteral("BUTTON");
const stcClsW = std.unicode.utf8ToUtf16LeStringLiteral("STATIC");

var g_hInst: ?HINSTANCE = null;
var g_parent: ?HWND = null;
var pending: config.Config = .{};
var label_hwnds: [6]?HWND = .{ null, null, null, null, null, null };

fn down(v: i32) bool {
    return (@as(u16, @bitCast(GetAsyncKeyState(v))) & 0x8000) != 0;
}

fn captureHotkey() config.Hotkey {
    var guard: u32 = 0;
    while (guard < 200) : (guard += 1) {
        if (!down(0x10) and !down(0x11) and !down(0x12)) break;
        std.time.sleep(10 * std.time.ns_per_ms);
    }
    while (true) {
        if (down(0x1B)) return .{ .mod = 0, .vk = 0x1B };
        var mod: u32 = 0;
        if (down(0x11)) mod |= config.MOD_CONTROL;
        if (down(0x10)) mod |= config.MOD_SHIFT;
        if (down(0x12)) mod |= config.MOD_ALT;

        var vk: u32 = 0x70;
        while (vk <= 0x7B) : (vk += 1) {
            if (down(@intCast(vk))) return .{ .mod = mod, .vk = vk };
        }
        vk = 0x41;
        while (vk <= 0x5A) : (vk += 1) {
            if (down(@intCast(vk))) return .{ .mod = mod, .vk = vk };
        }
        vk = 0x30;
        while (vk <= 0x39) : (vk += 1) {
            if (down(@intCast(vk))) return .{ .mod = mod, .vk = vk };
        }
        std.time.sleep(10 * std.time.ns_per_ms);
    }
}

fn getHotkeyPtr(i: usize) *config.Hotkey {
    return switch (i) {
        0 => &pending.hk_convert,
        1 => &pending.hk_reverse,
        2 => &pending.hk_case,
        3 => &pending.hk_search,
        4 => &pending.hk_translate,
        else => &pending.hk_qr,
    };
}

fn refreshLabel(i: usize, allocator: std.mem.Allocator) void {
    const lbl = config.hotkeyLabel(getHotkeyPtr(i).*, allocator);
    defer allocator.free(lbl);
    const w = std.unicode.utf8ToUtf16LeAlloc(allocator, lbl) catch return;
    defer allocator.free(w);
    const z = allocator.alloc(u16, w.len + 1) catch return;
    defer allocator.free(z);
    @memcpy(z[0..w.len], w);
    z[w.len] = 0;
    const zs: [:0]u16 = z[0..w.len :0];
    if (label_hwnds[i]) |h| {
        _ = SetWindowTextW(h, zs);
    }
}

fn createControl(class: windows.LPCWSTR, text: windows.LPCWSTR, style: windows.DWORD, x: i32, y: i32, w: i32, h: i32, id: usize, parent: HWND) ?HWND {
    const hMenu: ?windows.HMENU = if (id == 0) null else @ptrFromInt(id);
    return CreateWindowExW(0, class, text, WS_CHILD | WS_VISIBLE | style, x, y, w, h, parent, hMenu, g_hInst, null);
}

fn settingsProc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    const allocator = std.heap.page_allocator;
    switch (Msg) {
        WM_COMMAND => {
            const id = wParam & 0xFFFF;
            if (id >= BTN_CHANGE_BASE and id < BTN_CHANGE_BASE + 6) {
                const idx = id - BTN_CHANGE_BASE;
                const hk = captureHotkey();
                if (hk.vk != 0x1B) {
                    getHotkeyPtr(idx).* = hk;
                    refreshLabel(idx, allocator);
                }
                return 0;
            }
            if (id == ID_OK) {
                pending.ignore_upper_case = (SendMessageW(@ptrFromInt(ID_CHK_UPPER), BM_GETCHECK, 0, 0) != 0);
                pending.ignore_english = (SendMessageW(@ptrFromInt(ID_CHK_ENG), BM_GETCHECK, 0, 0) != 0);
                pending.enable_middle_mouse = (SendMessageW(@ptrFromInt(ID_CHK_MOUSE), BM_GETCHECK, 0, 0) != 0);
                config.g_config = pending;
                config.save(pending, allocator);
                if (g_parent) |p| {
                    const hotkey = @import("hotkey.zig");
                    hotkey.unregisterHotkeys(p);
                    _ = hotkey.registerHotkeys(p, pending);
                }
                _ = DestroyWindow(hWnd);
                return 0;
            }
            return 0;
        },
        WM_CLOSE => {
            _ = DestroyWindow(hWnd);
            return 0;
        },
        else => return DefWindowProcW(hWnd, Msg, wParam, lParam),
    }
}

fn chkHwnd(id: usize) HWND {
    return @ptrFromInt(id);
}

pub fn openSettings(hInst: ?HINSTANCE, parent: ?HWND) void {
    g_hInst = hInst;
    g_parent = parent;
    pending = config.g_config;
    const allocator = std.heap.page_allocator;

    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW), .style = 0, .lpfnWndProc = settingsProc,
        .cbClsExtra = 0, .cbWndExtra = 0, .hInstance = hInst, .hIcon = null,
        .hCursor = null, .hbrBackground = null, .lpszMenuName = null,
        .lpszClassName = clsW, .hIconSm = null,
    };
    _ = RegisterClassExW(&wc);

    const hWnd = CreateWindowExW(0, clsW, titleW, 0x00CF0000, 100, 100, 460, 420, parent, null, hInst, null) orelse return;

    const c1 = std.unicode.utf8ToUtf16LeStringLiteral("Ignore Upper case when converting");
    const c2 = std.unicode.utf8ToUtf16LeStringLiteral("Ignore English when reversing text");
    const c3 = std.unicode.utf8ToUtf16LeStringLiteral("Enable operation with mouse middle button");
    _ = createControl(btnClsW, c1, BS_CHECKBOX, 20, 20, 400, 24, ID_CHK_UPPER, hWnd);
    _ = createControl(btnClsW, c2, BS_CHECKBOX, 20, 48, 400, 24, ID_CHK_ENG, hWnd);
    _ = createControl(btnClsW, c3, BS_CHECKBOX, 20, 76, 400, 24, ID_CHK_MOUSE, hWnd);

    if (pending.ignore_upper_case) _ = SendMessageW(chkHwnd(ID_CHK_UPPER), BM_SETCHECK, 1, 0);
    if (pending.ignore_english) _ = SendMessageW(chkHwnd(ID_CHK_ENG), BM_SETCHECK, 1, 0);
    if (pending.enable_middle_mouse) _ = SendMessageW(chkHwnd(ID_CHK_MOUSE), BM_SETCHECK, 1, 0);

    const names = [_]windows.LPCWSTR{
        std.unicode.utf8ToUtf16LeStringLiteral("Convert  abc <-> FA"),
        std.unicode.utf8ToUtf16LeStringLiteral("Reverse  FA <-> abc"),
        std.unicode.utf8ToUtf16LeStringLiteral("Case     abc <-> ABC"),
        std.unicode.utf8ToUtf16LeStringLiteral("Search in Google"),
        std.unicode.utf8ToUtf16LeStringLiteral("Translate"),
        std.unicode.utf8ToUtf16LeStringLiteral("QR Code"),
    };
    const chW = std.unicode.utf8ToUtf16LeStringLiteral("Change Key");
    const emptyW = std.unicode.utf8ToUtf16LeStringLiteral("");

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const y: i32 = @intCast(110 + i * 34);
        _ = createControl(btnClsW, chW, BS_PUSHBUTTON, 20, y, 100, 28, BTN_CHANGE_BASE + i, hWnd);
        _ = createControl(stcClsW, names[i], 0, 130, y + 5, 200, 22, 0, hWnd);
        label_hwnds[i] = createControl(stcClsW, emptyW, 0, 340, y + 5, 90, 22, 3001 + i, hWnd);
        refreshLabel(i, allocator);
    }

    const okW = std.unicode.utf8ToUtf16LeStringLiteral("OK / Save");
    _ = createControl(btnClsW, okW, BS_PUSHBUTTON, 20, 330, 120, 32, ID_OK, hWnd);

    _ = ShowWindow(hWnd, SW_SHOW);
    _ = UpdateWindow(hWnd);
}
