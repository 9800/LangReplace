const std = @import("std");
const windows = std.os.windows;
const config = @import("config.zig");
const hotkey = @import("hotkey.zig");

const HWND = windows.HWND;
const UINT = windows.UINT;
const WPARAM = windows.WPARAM;
const LPARAM = windows.LPARAM;
const LRESULT = windows.LRESULT;
const HINSTANCE = windows.HINSTANCE;
const BOOL = windows.BOOL;
const DWORD = windows.DWORD;
const HDC = ?*anyopaque;
const HBRUSH = ?*anyopaque;
const HGDIOBJ = ?*anyopaque;
const HRGN = ?*anyopaque;
const HKL = ?*anyopaque;

const BAR_W: i32 = 356;
const BAR_H: i32 = 44;
const SEG_W: i32 = 56;
const BAR_TIMER: usize = 777;

const WM_ERASEBKGND: UINT = 0x0014;
const WM_PAINT: UINT = 0x000F;
const WM_LBUTTONDOWN: UINT = 0x0201;
const WM_NCHITTEST: UINT = 0x0084;
const WM_TIMER: UINT = 0x0113;
const HTCAPTION: LRESULT = 2;
const WS_POPUP: DWORD = 0x80000000;
const WS_VISIBLE: DWORD = 0x10000000;
const WS_EX_TOPMOST: DWORD = 0x8;
const WS_EX_TOOLWINDOW: DWORD = 0x80;
const SW_HIDE: i32 = 0;
const SW_SHOW: i32 = 5;
const DT_CENTER: u32 = 0x1;
const DT_VCENTER: u32 = 0x4;
const DT_SINGLELINE: u32 = 0x20;
const WM_INPUTLANGCHANGEREQUEST: UINT = 0x0050;

extern "user32" fn RegisterClassExW(w: *const WNDCLASSEXW) callconv(windows.WINAPI) u16;
extern "user32" fn CreateWindowExW(a: DWORD, b: windows.LPCWSTR, c: windows.LPCWSTR, d: DWORD, e: i32, f: i32, g: i32, h: i32, i: ?HWND, j: ?windows.HMENU, k: ?HINSTANCE, l: ?*anyopaque) callconv(windows.WINAPI) ?HWND;
extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, w: WPARAM, l: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn ShowWindow(hWnd: HWND, n: i32) callconv(windows.WINAPI) BOOL;
extern "user32" fn IsWindowVisible(hWnd: HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn InvalidateRect(hWnd: HWND, r: ?*const windows.RECT, erase: BOOL) callconv(windows.WINAPI) BOOL;
extern "user32" fn SetTimer(hWnd: ?HWND, id: usize, ms: UINT, cb: ?*const fn (?HWND, UINT, usize, DWORD) callconv(windows.WINAPI) void) callconv(windows.WINAPI) usize;
extern "user32" fn GetKeyState(v: i32) callconv(windows.WINAPI) i16;
extern "user32" fn GetKeyboardLayout(tid: DWORD) callconv(windows.WINAPI) HKL;
extern "user32" fn GetWindowThreadProcessId(hWnd: HWND, p: ?*DWORD) callconv(windows.WINAPI) DWORD;
extern "user32" fn GetForegroundWindow() callconv(windows.WINAPI) ?HWND;
extern "user32" fn LoadKeyboardLayoutW(klid: [*:0]const u16, flags: UINT) callconv(windows.WINAPI) HKL;
extern "user32" fn PostMessageW(hWnd: HWND, Msg: UINT, w: WPARAM, l: LPARAM) callconv(windows.WINAPI) BOOL;
extern "user32" fn BeginPaint(hWnd: HWND, ps: *PAINTSTRUCT) callconv(windows.WINAPI) HDC;
extern "user32" fn EndPaint(hWnd: HWND, ps: *const PAINTSTRUCT) callconv(windows.WINAPI) BOOL;
extern "user32" fn FillRect(hdc: HDC, r: *const windows.RECT, b: HBRUSH) callconv(windows.WINAPI) BOOL;
extern "user32" fn FrameRect(hdc: HDC, r: *const windows.RECT, b: HBRUSH) callconv(windows.WINAPI) BOOL;
extern "user32" fn DrawTextW(hdc: HDC, s: [*]const u16, c: i32, r: *windows.RECT, fmt: u32) callconv(windows.WINAPI) i32;
extern "user32" fn SetWindowRgn(hWnd: HWND, hRgn: HRGN, b: BOOL) callconv(windows.WINAPI) BOOL;
extern "user32" fn SendInput(c: UINT, p: *INPUT, size: i32) callconv(windows.WINAPI) UINT;
extern "gdi32" fn CreateSolidBrush(c: u32) callconv(windows.WINAPI) HBRUSH;
extern "gdi32" fn CreateRoundRectRgn(l: i32, t: i32, r: i32, b: i32, w: i32, h: i32) callconv(windows.WINAPI) HRGN;
extern "gdi32" fn RoundRect(hdc: HDC, l: i32, t: i32, r: i32, b: i32, w: i32, h: i32) callconv(windows.WINAPI) BOOL;
extern "gdi32" fn CreatePen(s: i32, w: i32, c: u32) callconv(windows.WINAPI) ?*anyopaque;
extern "gdi32" fn SelectObject(hdc: HDC, o: HGDIOBJ) callconv(windows.WINAPI) HGDIOBJ;
extern "gdi32" fn DeleteObject(o: HGDIOBJ) callconv(windows.WINAPI) BOOL;
extern "gdi32" fn SetBkMode(hdc: HDC, m: i32) callconv(windows.WINAPI) i32;
extern "gdi32" fn SetTextColor(hdc: HDC, c: u32) callconv(windows.WINAPI) u32;

const WNDCLASSEXW = extern struct {
    cbSize: UINT, style: UINT,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(windows.WINAPI) LRESULT,
    cbClsExtra: i32, cbWndExtra: i32, hInstance: ?HINSTANCE,
    hIcon: ?windows.HICON, hCursor: ?windows.HCURSOR, hbrBackground: ?windows.HBRUSH,
    lpszMenuName: ?windows.LPCWSTR, lpszClassName: windows.LPCWSTR, hIconSm: ?windows.HICON,
};

const PAINTSTRUCT = extern struct {
    hdc: HDC,
    fErase: BOOL,
    rcPaint: windows.RECT,
    fRestore: BOOL,
    fIncUpdate: BOOL,
    rgbReserved: [32]u8,
};

const KEYBDINPUT = extern struct { wVk: u16, wScan: u16, dwFlags: DWORD, time: DWORD, dwExtraInfo: usize };
const INPUT_U = extern union { ki: KEYBDINPUT, pad: [32]u8 };
const INPUT = extern struct { type: DWORD, u: INPUT_U };

const barClsW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceBar");
const klidFaW = std.unicode.utf8ToUtf16LeStringLiteral("00000429");
const klidEnW = std.unicode.utf8ToUtf16LeStringLiteral("00000409");

var bar_hwnd: ?HWND = null;
var g_main_hwnd: ?HWND = null;
var g_enabled: bool = true;

fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}
const COL_BAR = rgb(205, 220, 240);
const COL_LABEL = rgb(40, 60, 140);
const COL_ON = rgb(110, 200, 90);
const COL_OFF = rgb(185, 185, 185);
const COL_OFFLR = rgb(220, 90, 80);
const COL_SEG = rgb(235, 242, 252);

fn keyBit(vk: i32) bool {
    return (@as(u16, @bitCast(GetKeyState(vk))) & 1) != 0;
}

fn isFaLayout() bool {
    const fg = GetForegroundWindow() orelse return false;
    const tid = GetWindowThreadProcessId(fg, null);
    const hkl = GetKeyboardLayout(tid) orelse return false;
    const id = @as(u32, @intCast(@intFromPtr(hkl))) & 0xFFFF;
    return id == 0x0429;
}

fn tapKey(vk: u16) void {
    var inputs: [2]INPUT = .{
        .{ .type = 1, .u = .{ .ki = .{ .wVk = vk, .wScan = 0, .dwFlags = 0, .time = 0, .dwExtraInfo = 0 } } },
        .{ .type = 1, .u = .{ .ki = .{ .wVk = vk, .wScan = 0, .dwFlags = 2, .time = 0, .dwExtraInfo = 0 } } },
    };
    _ = SendInput(2, &inputs[0], @sizeOf(INPUT));
}

fn toggleLayout() void {
    const fg = GetForegroundWindow() orelse return;
    const klid: [*:0]const u16 = if (isFaLayout()) klidEnW else klidFaW;
    const hkl = LoadKeyboardLayoutW(klid, 1) orelse return;
    // ✅ تبدیل امن به LPARAM
    _ = PostMessageW(fg, WM_INPUTLANGCHANGEREQUEST, 0, @as(LPARAM, @bitCast(@intFromPtr(hkl))));
}

fn toggleProgram() void {
    g_enabled = !g_enabled;
    if (g_main_hwnd) |h| {
        if (g_enabled) {
            _ = hotkey.registerHotkeys(h, config.g_config);
        } else {
            hotkey.unregisterHotkeys(h);
        }
    }
}

fn isOn(i: usize) bool {
    return switch (i) {
        0 => isFaLayout(),
        1 => keyBit(0x14),
        2 => keyBit(0x90),
        3 => keyBit(0x2D),
        4 => keyBit(0x91),
        else => g_enabled,
    };
}

fn segLabel(i: usize) []const u8 {
    return switch (i) {
        0 => if (isFaLayout()) "FA" else "EN",
        1 => "CAPS",
        2 => "NUM",
        3 => "INS",
        4 => "SCR",
        else => "LR",
    };
}

fn toWideBuf(buf: []u16, s: []const u8) usize {
    var di: usize = 0;
    var view = std.unicode.Utf8View.init(s) catch return 0;
    var it = view.iterator();
    while (it.nextCodepoint()) |cp| {
        if (di >= buf.len - 1) break;
        if (cp < 0x10000) {
            buf[di] = @intCast(cp);
            di += 1;
        }
    }
    buf[di] = 0;
    return di;
}

fn barProc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    switch (Msg) {
        WM_NCHITTEST => return HTCAPTION,
        WM_TIMER => {
            _ = InvalidateRect(hWnd, null, 1);
            return 0;
        },
        WM_ERASEBKGND => {
            const hdc: HDC = @ptrFromInt(wParam);
            var r = windows.RECT{ .left = 0, .top = 0, .right = BAR_W, .bottom = BAR_H };
            const br = CreateSolidBrush(COL_BAR);
            _ = FillRect(hdc, &r, br);
            _ = DeleteObject(br);
            return 1;
        },
        WM_PAINT => {
            var ps: PAINTSTRUCT = undefined;
            const dc = BeginPaint(hWnd, &ps);
            if (dc) |hdc| {
                var i: usize = 0;
                while (i < 6) : (i += 1) {
                    const x: i32 = @intCast(4 + i * (SEG_W + 2));
                    var sr = windows.RECT{ .left = x, .top = 3, .right = x + SEG_W, .bottom = BAR_H - 3 };
                    const sb = CreateSolidBrush(COL_SEG);
                    _ = FillRect(hdc, &sr, sb);
                    _ = DeleteObject(sb);
                    const bd = CreateSolidBrush(rgb(150, 165, 195));
                    _ = FrameRect(hdc, &sr, bd);
                    _ = DeleteObject(bd);

                    var buf: [16]u16 = undefined;
                    _ = toWideBuf(&buf, segLabel(i));
                    _ = SetBkMode(hdc, 1);
                    _ = SetTextColor(hdc, COL_LABEL);
                    var tr = windows.RECT{ .left = x, .top = 4, .right = x + SEG_W, .bottom = 20 };
                    _ = DrawTextW(hdc, &buf, -1, &tr, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

                    const on = isOn(i);
                    const ledCol = if (on) COL_ON else (if (i == 5) COL_OFFLR else COL_OFF);
                    var lr = windows.RECT{ .left = x + 8, .top = 25, .right = x + SEG_W - 8, .bottom = 36 };
                    const lb = CreateSolidBrush(ledCol);
                    _ = FillRect(hdc, &lr, lb);
                    _ = DeleteObject(lb);
                    const lb2 = CreateSolidBrush(rgb(120, 130, 150));
                    _ = FrameRect(hdc, &lr, lb2);
                    _ = DeleteObject(lb2);
                }
            }
            _ = EndPaint(hWnd, &ps);
            return 0;
        },
        WM_LBUTTONDOWN => {
            const x = @as(i32, @intCast(@as(i16, @truncate(lParam))));
            if (x >= 4) {
                const i = @as(usize, @intCast(@divTrunc(x - 4, SEG_W + 2)));
                if (i < 6) {
                    switch (i) {
                        0 => toggleLayout(),
                        1 => tapKey(0x14),
                        2 => tapKey(0x90),
                        3 => tapKey(0x2D),
                        4 => tapKey(0x91),
                        else => toggleProgram(),
                    }
                    _ = InvalidateRect(hWnd, null, 1);
                }
            }
            return 0;
        },
        else => return DefWindowProcW(hWnd, Msg, wParam, lParam),
    }
}

pub fn createBar(hInst: ?HINSTANCE, mainHwnd: ?HWND) void {
    g_main_hwnd = mainHwnd;

    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW), .style = 0, .lpfnWndProc = barProc,
        .cbClsExtra = 0, .cbWndExtra = 0, .hInstance = hInst, .hIcon = null,
        .hCursor = null, .hbrBackground = null, .lpszMenuName = null,
        .lpszClassName = barClsW, .hIconSm = null,
    };
    _ = RegisterClassExW(&wc);

    const titleW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplace Bar");

    bar_hwnd = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_TOOLWINDOW, barClsW, titleW,
        WS_POPUP | WS_VISIBLE, 120, 120, BAR_W, BAR_H,
        null, null, hInst, null,
    );

    if (bar_hwnd) |h| {
        const rgn = CreateRoundRectRgn(0, 0, BAR_W + 1, BAR_H + 1, 14, 14) orelse return;
        _ = SetWindowRgn(h, rgn, 1);
        _ = SetTimer(h, BAR_TIMER, 500, null);
    }
}

pub fn toggleBarVisible() void {
    if (bar_hwnd) |h| {
        if (IsWindowVisible(h) != 0) {
            _ = ShowWindow(h, SW_HIDE);
        } else {
            _ = ShowWindow(h, SW_SHOW);
        }
    }
}
