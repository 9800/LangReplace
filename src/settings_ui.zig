const std = @import("std");
const windows = std.os.windows;
const config = @import("config.zig");
const lang = @import("lang.zig");
const autostart = @import("autostart.zig");

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
const HPEN = ?*anyopaque;
const HGDIOBJ = ?*anyopaque;
const HRGN = ?*anyopaque;
const HHOOK = ?*anyopaque;

const BTN_CHANGE_BASE: usize = 2101;
const ID_CHK_UPPER: usize = 2001;
const ID_CHK_ENG: usize = 2002;
const ID_CHK_MOUSE: usize = 2003;
const ID_CHK_AUTO: usize = 2004;
const ID_OK: usize = 2301;
const ID_CLOSE: usize = 2302;
const ID_LANG: usize = 2401;
const ID_PICK_FA: usize = 9001;
const ID_PICK_EN: usize = 9002;
const CAPTURE_TIMER: usize = 999;

const WS_POPUP: DWORD = 0x80000000;
const WS_CHILD: DWORD = 0x40000000;
const WS_VISIBLE: DWORD = 0x10000000;
const BS_CHECKBOX: DWORD = 0x3;
const BS_OWNERDRAW: DWORD = 0xB;
const WM_CLOSE: UINT = 0x0010;
const WM_COMMAND: UINT = 0x0111;
const WM_ERASEBKGND: UINT = 0x0014;
const WM_CTLCOLORSTATIC: UINT = 0x0138;
const WM_DRAWITEM: UINT = 0x002B;
const WM_NCHITTEST: UINT = 0x0084;
const WM_TIMER: UINT = 0x0113;
const BM_GETCHECK: UINT = 0x00F0;
const BM_SETCHECK: UINT = 0x00F1;
const STM_SETICON: UINT = 0x0170;
const SW_SHOW: i32 = 5;
const WS_EX_TOPMOST: DWORD = 0x00000008;
const HTCAPTION: LRESULT = 2;
const DT_CENTER: u32 = 0x1;
const DT_VCENTER: u32 = 0x4;
const DT_SINGLELINE: u32 = 0x20;
const WH_KEYBOARD_LL: i32 = 13;
const SS_ICON: DWORD = 0x3;
const SS_CENTERIMAGE: DWORD = 0x200;
const SM_CXSCREEN: i32 = 0;
const SM_CYSCREEN: i32 = 1;
const PM_REMOVE: UINT = 0x0001;

// 🎨 پالت رنگی
fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}
const COL_BG = rgb(243, 240, 255);
const COL_SPLASH_BG = rgb(255, 255, 255);
const COL_TEXT = rgb(70, 40, 160);
const COL_TITLE = rgb(90, 50, 190);
const COL_SUB = rgb(120, 100, 160);
const COL_BTN = rgb(124, 77, 255);
const COL_OK = rgb(46, 175, 110);
const COL_LANG = rgb(33, 150, 243);
const COL_CLOSE = rgb(229, 57, 53);
const COL_WHITE = rgb(255, 255, 255);

var bg_brush: HBRUSH = null;
var splash_brush: HBRUSH = null;
var in_splash: bool = false;

fn ensureBrushes() void {
    if (bg_brush == null) bg_brush = CreateSolidBrush(COL_BG);
    if (splash_brush == null) splash_brush = CreateSolidBrush(COL_SPLASH_BG);
}

const PMSG = extern struct {
    hwnd: ?HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: extern struct { x: i32, y: i32 },
};

const DRAWITEMSTRUCT = extern struct {
    CtlType: UINT,
    CtlID: UINT,
    itemID: UINT,
    itemAction: UINT,
    itemState: UINT,
    hwndItem: HWND,
    hDC: HDC,
    rcItem: windows.RECT,
    itemData: usize,
};

const KBDLLHOOKSTRUCT = extern struct {
    vkCode: DWORD,
    scanCode: DWORD,
    flags: DWORD,
    time: DWORD,
    dwExtraInfo: usize,
};

extern "user32" fn RegisterClassExW(w: *const WNDCLASSEXW) callconv(windows.WINAPI) u16;
extern "user32" fn CreateWindowExW(a: DWORD, b: windows.LPCWSTR, c: windows.LPCWSTR, d: DWORD, e: i32, f: i32, g: i32, h: i32, i: ?HWND, j: ?windows.HMENU, k: ?HINSTANCE, l: ?*anyopaque) callconv(windows.WINAPI) ?HWND;
extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, w: WPARAM, l: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn ShowWindow(hWnd: HWND, n: i32) callconv(windows.WINAPI) BOOL;
extern "user32" fn UpdateWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn DestroyWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn SendMessageW(hWnd: HWND, Msg: UINT, w: WPARAM, l: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn SetWindowTextW(hWnd: HWND, s: [*:0]const u16) callconv(windows.WINAPI) BOOL;
extern "user32" fn GetAsyncKeyState(v: i32) callconv(windows.WINAPI) i16;
extern "user32" fn GetMessageW(lpMsg: *PMSG, hWnd: ?HWND, a: UINT, b: UINT) callconv(windows.WINAPI) BOOL;
extern "user32" fn PeekMessageW(lpMsg: *PMSG, hWnd: ?HWND, a: UINT, b: UINT, remove: UINT) callconv(windows.WINAPI) BOOL;
extern "user32" fn TranslateMessage(m: *const PMSG) callconv(windows.WINAPI) BOOL;
extern "user32" fn DispatchMessageW(m: *const PMSG) callconv(windows.WINAPI) LRESULT;
extern "user32" fn FillRect(hdc: HDC, r: *const windows.RECT, b: HBRUSH) callconv(windows.WINAPI) BOOL;
extern "user32" fn DrawTextW(hdc: HDC, s: [*]const u16, c: i32, r: *windows.RECT, fmt: u32) callconv(windows.WINAPI) i32;
extern "user32" fn GetWindowTextW(hWnd: HWND, s: [*]u16, c: i32) callconv(windows.WINAPI) i32;
extern "user32" fn SetWindowRgn(hWnd: HWND, hRgn: HRGN, bRedraw: BOOL) callconv(windows.WINAPI) BOOL;
extern "user32" fn SetWindowsHookExW(idHook: i32, lpfn: *const fn (i32, WPARAM, LPARAM) callconv(windows.WINAPI) LRESULT, hMod: ?HINSTANCE, dwThreadId: DWORD) callconv(windows.WINAPI) HHOOK;
extern "user32" fn UnhookWindowsHookEx(h: HHOOK) callconv(windows.WINAPI) BOOL;
extern "user32" fn CallNextHookEx(h: HHOOK, code: i32, wp: WPARAM, lp: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn SetTimer(hWnd: ?HWND, nIDEvent: usize, uElapse: UINT, lpTimerFunc: ?*const fn (?HWND, UINT, usize, DWORD) callconv(windows.WINAPI) void) callconv(windows.WINAPI) usize;
extern "user32" fn KillTimer(hWnd: ?HWND, uIDEvent: usize) callconv(windows.WINAPI) BOOL;
extern "user32" fn GetSystemMetrics(i: i32) callconv(windows.WINAPI) i32;
extern "kernel32" fn Sleep(ms: DWORD) callconv(windows.WINAPI) void;
extern "gdi32" fn CreateSolidBrush(c: u32) callconv(windows.WINAPI) HBRUSH;
extern "gdi32" fn CreatePen(style: i32, width: i32, color: u32) callconv(windows.WINAPI) HPEN;
extern "gdi32" fn CreateRoundRectRgn(l: i32, t: i32, r: i32, b: i32, wr: i32, hr: i32) callconv(windows.WINAPI) HRGN;
extern "gdi32" fn SelectObject(hdc: HDC, o: HGDIOBJ) callconv(windows.WINAPI) HGDIOBJ;
extern "gdi32" fn DeleteObject(o: HGDIOBJ) callconv(windows.WINAPI) BOOL;
extern "gdi32" fn RoundRect(hdc: HDC, l: i32, t: i32, r: i32, b: i32, w: i32, h: i32) callconv(windows.WINAPI) BOOL;
extern "gdi32" fn SetBkMode(hdc: HDC, mode: i32) callconv(windows.WINAPI) i32;
extern "gdi32" fn SetTextColor(hdc: HDC, c: u32) callconv(windows.WINAPI) u32;

const WNDCLASSEXW = extern struct {
    cbSize: UINT, style: UINT,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(windows.WINAPI) LRESULT,
    cbClsExtra: i32, cbWndExtra: i32, hInstance: ?HINSTANCE,
    hIcon: ?windows.HICON, hCursor: ?windows.HCURSOR, hbrBackground: ?windows.HBRUSH,
    lpszMenuName: ?windows.LPCWSTR, lpszClassName: windows.LPCWSTR, hIconSm: ?windows.HICON,
};

const clsW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceSettings");
const pickClsW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceLangPick");
const splashClsW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceSplash");
const btnClsW = std.unicode.utf8ToUtf16LeStringLiteral("BUTTON");
const stcClsW = std.unicode.utf8ToUtf16LeStringLiteral("STATIC");

var g_hInst: ?HINSTANCE = null;
var g_parent: ?HWND = null;
var g_settings_hwnd: ?HWND = null;
var pending: config.Config = .{};
var label_hwnds: [6]?HWND = .{ null, null, null, null, null, null };
var lang_btn: ?HWND = null;
var chk_hwnds: [4]?HWND = .{ null, null, null, null };
var lang_choice: i32 = -1;
var g_hook: HHOOK = null;
var capturing: i32 = -1;

fn roundRgn(hWnd: HWND, w: i32, h: i32) void {
    const rgn = CreateRoundRectRgn(0, 0, w + 1, h + 1, 28, 28) orelse return;
    _ = SetWindowRgn(hWnd, rgn, 1);
}

fn mkWide(allocator: std.mem.Allocator, s: []const u8) ?[:0]u16 {
    const w = std.unicode.utf8ToUtf16LeAlloc(allocator, s) catch return null;
    defer allocator.free(w);
    const z = allocator.alloc(u16, w.len + 1) catch return null;
    @memcpy(z[0..w.len], w);
    z[w.len] = 0;
    return z[0..w.len :0];
}

fn down(v: i32) bool {
    return (@as(u16, @bitCast(GetAsyncKeyState(v))) & 0x8000) != 0;
}

fn isModKey(v: u32) bool {
    return v == 0x10 or v == 0x11 or v == 0x12 or v == 0x1B or v == 0x5B or v == 0x5C;
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

fn setWide(hWnd: ?HWND, s: []const u8) void {
    const allocator = std.heap.page_allocator;
    const w = mkWide(allocator, s) orelse return;
    defer allocator.free(w);
    if (hWnd) |h| _ = SetWindowTextW(h, w);
}

fn refreshLabel(i: usize, allocator: std.mem.Allocator) void {
    const lbl = config.hotkeyLabel(getHotkeyPtr(i).*, allocator);
    defer allocator.free(lbl);
    const w = mkWide(allocator, lbl) orelse return;
    defer allocator.free(w);
    if (label_hwnds[i]) |h| _ = SetWindowTextW(h, w);
}

fn langLabel() []const u8 {
    return if (pending.language == 1)
        lang.t("Language: Persian", "زبان: فارسی")
    else
        lang.t("Language: English", "زبان: English");
}

fn endCapture() void {
    if (g_hook) |h| {
        _ = UnhookWindowsHookEx(h);
        g_hook = null;
    }
    if (g_settings_hwnd) |h| _ = KillTimer(h, CAPTURE_TIMER);
    const idx = capturing;
    capturing = -1;
    if (idx >= 0) refreshLabel(@intCast(idx), std.heap.page_allocator);
}

fn kbHookProc(code: i32, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    if (code >= 0 and capturing >= 0 and (wParam == 0x0100 or wParam == 0x0104)) {
        const ks: *KBDLLHOOKSTRUCT = @ptrFromInt(@as(usize, @bitCast(lParam)));
        const vk = ks.vkCode;

        if (vk == 0x1B) {
            endCapture();
            return 1;
        }

        if (!isModKey(vk)) {
            var mod: u32 = 0;
            if (down(0x11)) mod |= config.MOD_CONTROL;
            if (down(0x10)) mod |= config.MOD_SHIFT;
            if (down(0x12)) mod |= config.MOD_ALT;
            getHotkeyPtr(@intCast(capturing)).* = .{ .mod = mod, .vk = vk };
            endCapture();
        }
        return 1;
    }
    return CallNextHookEx(null, code, wParam, lParam);
}

fn startCapture(idx: usize) void {
    if (capturing >= 0) return;
    capturing = @intCast(idx);
    setWide(label_hwnds[idx], "...");
    g_hook = SetWindowsHookExW(WH_KEYBOARD_LL, kbHookProc, null, 0);
    if (g_settings_hwnd) |h| _ = SetTimer(h, CAPTURE_TIMER, 15000, null);
}

fn addControl(parent: HWND, classW: windows.LPCWSTR, textUtf8: []const u8, style: DWORD, x: i32, y: i32, w: i32, h: i32, id: usize) ?HWND {
    const allocator = std.heap.page_allocator;
    const tw = mkWide(allocator, textUtf8) orelse return null;
    defer allocator.free(tw);
    const hMenu: ?windows.HMENU = if (id == 0) null else @ptrFromInt(id);
    return CreateWindowExW(0, classW, tw, WS_CHILD | WS_VISIBLE | style, x, y, w, h, parent, hMenu, g_hInst, null);
}

fn colorMessages(Msg: UINT, wParam: WPARAM, lParam: LPARAM) ?LRESULT {
    switch (Msg) {
        WM_ERASEBKGND => {
            const hdc: HDC = @ptrFromInt(wParam);
            var r = windows.RECT{ .left = 0, .top = 0, .right = 4000, .bottom = 4000 };
            ensureBrushes();
            const br = if (in_splash) splash_brush else bg_brush;
            _ = FillRect(hdc, &r, br);
            return 1;
        },
        WM_CTLCOLORSTATIC => {
            const hdc: HDC = @ptrFromInt(wParam);
            const col = if (in_splash) COL_TITLE else COL_TEXT;
            _ = SetTextColor(hdc, col);
            _ = SetBkMode(hdc, 1);
            ensureBrushes();
            const br = if (in_splash) splash_brush else bg_brush;
            return @as(LRESULT, @intCast(@intFromPtr(br)));
        },
        WM_DRAWITEM => {
            const dis: *DRAWITEMSTRUCT = @ptrFromInt(@as(usize, @bitCast(lParam)));
            if (dis.hDC) |dc| {
                const id = dis.CtlID;
                const fill = if (id == ID_OK) COL_OK else if (id == ID_CLOSE) COL_CLOSE else if (id == ID_LANG) COL_LANG else if (id == ID_PICK_FA) COL_BTN else if (id == ID_PICK_EN) COL_LANG else COL_BTN;
                const br = CreateSolidBrush(fill);
                const pen = CreatePen(0, 2, fill);
                const oldB = SelectObject(dc, br);
                const oldP = SelectObject(dc, pen);
                const r = dis.rcItem;
                _ = RoundRect(dc, r.left, r.top, r.right, r.bottom, 14, 14);
                var buf: [128]u16 = undefined;
                const n = GetWindowTextW(dis.hwndItem, &buf, buf.len);
                if (n > 0) {
                    _ = SetBkMode(dc, 1);
                    _ = SetTextColor(dc, COL_WHITE);
                    var tr = r;
                    _ = DrawTextW(dc, &buf, n, &tr, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
                }
                _ = SelectObject(dc, oldB);
                _ = SelectObject(dc, oldP);
                _ = DeleteObject(br);
                _ = DeleteObject(pen);
            }
            return 1;
        },
        else => return null,
    }
}

// ===== Splash Screen =====
fn splashProc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    if (colorMessages(Msg, wParam, lParam)) |r| return r;
    return DefWindowProcW(hWnd, Msg, wParam, lParam);
}

pub fn showSplash(hInst: ?HINSTANCE, icon: ?windows.HICON) void {
    const allocator = std.heap.page_allocator;

    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW), .style = 0, .lpfnWndProc = splashProc,
        .cbClsExtra = 0, .cbWndExtra = 0, .hInstance = hInst, .hIcon = icon,
        .hCursor = null, .hbrBackground = null, .lpszMenuName = null,
        .lpszClassName = splashClsW, .hIconSm = null,
    };
    _ = RegisterClassExW(&wc);

    const sw: i32 = 440;
    const sh: i32 = 260;
    const screenW = GetSystemMetrics(SM_CXSCREEN);
    const screenH = GetSystemMetrics(SM_CYSCREEN);
    // ✅ تقسیم صحیح اعداد علامت‌دار
    const x = @divTrunc(screenW - sw, 2);
    const y = @divTrunc(screenH - sh, 2);

    const titleW = mkWide(allocator, "LangReplace") orelse return;
    defer allocator.free(titleW);

    const hWnd = CreateWindowExW(
        WS_EX_TOPMOST, splashClsW, titleW,
        WS_POPUP, x, y, sw, sh,
        null, null, hInst, null,
    ) orelse return;

    roundRgn(hWnd, sw, sh);

    if (icon) |ic| {
        const emptyW = mkWide(allocator, "") orelse return;
        defer allocator.free(emptyW);
        if (CreateWindowExW(0, stcClsW, emptyW, WS_CHILD | WS_VISIBLE | SS_ICON | SS_CENTERIMAGE, 30, 50, 64, 64, hWnd, null, hInst, null)) |icHwnd| {
            _ = SendMessageW(icHwnd, STM_SETICON, @intFromPtr(ic), 0);
        }
    }

    _ = addControl(hWnd, stcClsW, "LangReplace", 0, 110, 50, 300, 50, 0);
    _ = addControl(hWnd, stcClsW, lang.t("Keyboard Layout Converter", "ابزار تبدیل چیدمان کیبورد"), 0, 110, 105, 300, 24, 0);
    _ = addControl(hWnd, stcClsW, "v1.0", 0, 110, 135, 300, 20, 0);
    _ = addControl(hWnd, stcClsW, lang.t("Programmer: Nikan Rayan 💜", "برنامه‌نویس: نیکان رایان 💜"), 0, 30, 210, 380, 24, 0);

    in_splash = true;
    _ = ShowWindow(hWnd, SW_SHOW);
    _ = UpdateWindow(hWnd);

    Sleep(3000);

    in_splash = false;
    _ = DestroyWindow(hWnd);

    var msg: PMSG = undefined;
    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) != 0) {
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
}

fn pickProc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    if (colorMessages(Msg, wParam, lParam)) |r| return r;
    switch (Msg) {
        WM_NCHITTEST => return HTCAPTION,
        WM_COMMAND => {
            const id = wParam & 0xFFFF;
            if (id == ID_PICK_FA) {
                lang_choice = 1;
                _ = DestroyWindow(hWnd);
                return 0;
            }
            if (id == ID_PICK_EN) {
                lang_choice = 0;
                _ = DestroyWindow(hWnd);
                return 0;
            }
            return 0;
        },
        WM_CLOSE => {
            lang_choice = 0;
            _ = DestroyWindow(hWnd);
            return 0;
        },
        else => return DefWindowProcW(hWnd, Msg, wParam, lParam),
    }
}

pub fn pickLanguage(hInst: ?HINSTANCE) u32 {
    lang_choice = -1;
    const allocator = std.heap.page_allocator;

    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW), .style = 0, .lpfnWndProc = pickProc,
        .cbClsExtra = 0, .cbWndExtra = 0, .hInstance = hInst, .hIcon = null,
        .hCursor = null, .hbrBackground = null, .lpszMenuName = null,
        .lpszClassName = pickClsW, .hIconSm = null,
    };
    _ = RegisterClassExW(&wc);

    const title = mkWide(allocator, "LangReplace - زبان / Language") orelse return 0;
    defer allocator.free(title);

    const hWnd = CreateWindowExW(WS_EX_TOPMOST, pickClsW, title, WS_POPUP | WS_VISIBLE, 400, 300, 420, 200, null, null, hInst, null) orelse return 0;
    roundRgn(hWnd, 420, 200);

    _ = addControl(hWnd, stcClsW, "زبان برنامه را انتخاب کنید\r\nChoose the interface language:", 0, 20, 15, 370, 40, 0);
    _ = addControl(hWnd, btnClsW, "فارسی", BS_OWNERDRAW, 40, 80, 150, 50, ID_PICK_FA);
    _ = addControl(hWnd, btnClsW, "English", BS_OWNERDRAW, 220, 80, 150, 50, ID_PICK_EN);
    _ = addControl(hWnd, stcClsW, lang.t("Programmer: Nikan Rayan", "برنامه‌نویس: نیکان رایان"), 0, 20, 145, 370, 20, 0);

    _ = ShowWindow(hWnd, SW_SHOW);
    _ = UpdateWindow(hWnd);

    var msg: PMSG = undefined;
    while (lang_choice == -1 and GetMessageW(&msg, null, 0, 0) != 0) {
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
    return if (lang_choice == 1) 1 else 0;
}

fn settingsProc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    if (colorMessages(Msg, wParam, lParam)) |r| return r;
    const allocator = std.heap.page_allocator;
    switch (Msg) {
        WM_NCHITTEST => return HTCAPTION,
        WM_TIMER => {
            if (wParam == CAPTURE_TIMER and capturing >= 0) {
                endCapture();
            }
            return 0;
        },
        WM_COMMAND => {
            const id = wParam & 0xFFFF;
            if (id >= BTN_CHANGE_BASE and id < BTN_CHANGE_BASE + 6) {
                startCapture(id - BTN_CHANGE_BASE);
                return 0;
            }
            if (id == ID_LANG) {
                pending.language = if (pending.language == 1) 0 else 1;
                setWide(lang_btn, langLabel());
                return 0;
            }
            if (id == ID_OK) {
                endCapture();
                if (chk_hwnds[0]) |h| pending.ignore_upper_case = (SendMessageW(h, BM_GETCHECK, 0, 0) != 0);
                if (chk_hwnds[1]) |h| pending.ignore_english = (SendMessageW(h, BM_GETCHECK, 0, 0) != 0);
                if (chk_hwnds[2]) |h| pending.enable_middle_mouse = (SendMessageW(h, BM_GETCHECK, 0, 0) != 0);
                if (chk_hwnds[3]) |h| pending.autostart = (SendMessageW(h, BM_GETCHECK, 0, 0) != 0);
                autostart.setAutostart(pending.autostart);
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
            if (id == ID_CLOSE) {
                endCapture();
                _ = DestroyWindow(hWnd);
                return 0;
            }
            return 0;
        },
        WM_CLOSE => {
            endCapture();
            _ = DestroyWindow(hWnd);
            return 0;
        },
        else => return DefWindowProcW(hWnd, Msg, wParam, lParam),
    }
}

pub fn openSettings(hInst: ?HINSTANCE, parent: ?HWND) void {
    g_hInst = hInst;
    g_parent = parent;
    pending = config.g_config;
    pending.autostart = autostart.getAutostart();
    const allocator = std.heap.page_allocator;

    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW), .style = 0, .lpfnWndProc = settingsProc,
        .cbClsExtra = 0, .cbWndExtra = 0, .hInstance = hInst, .hIcon = null,
        .hCursor = null, .hbrBackground = null, .lpszMenuName = null,
        .lpszClassName = clsW, .hIconSm = null,
    };
    _ = RegisterClassExW(&wc);

    const title = mkWide(allocator, lang.t("LangReplace - Settings", "LangReplace - تنظیمات")) orelse return;
    defer allocator.free(title);

    const hWnd = CreateWindowExW(0, clsW, title, WS_POPUP | WS_VISIBLE, 100, 80, 470, 520, parent, null, hInst, null) orelse return;
    g_settings_hwnd = hWnd;
    roundRgn(hWnd, 470, 520);

    chk_hwnds[0] = addControl(hWnd, btnClsW, lang.t("Ignore Upper case when converting", "نادیده گرفتن بزرگی حروف هنگام تبدیل"), BS_CHECKBOX, 20, 20, 410, 24, ID_CHK_UPPER);
    chk_hwnds[1] = addControl(hWnd, btnClsW, lang.t("Ignore English when reversing text", "نادیده گرفتن انگلیسی هنگام معکوس کردن"), BS_CHECKBOX, 20, 48, 410, 24, ID_CHK_ENG);
    chk_hwnds[2] = addControl(hWnd, btnClsW, lang.t("Enable operation with mouse middle button", "فعال‌سازی با دکمه وسط موس"), BS_CHECKBOX, 20, 76, 410, 24, ID_CHK_MOUSE);
    chk_hwnds[3] = addControl(hWnd, btnClsW, lang.t("Start with Windows (Auto-start)", "اجرا هنگام شروع ویندوز (آستارت خودکار)"), BS_CHECKBOX, 20, 104, 410, 24, ID_CHK_AUTO);

    if (pending.ignore_upper_case) {
        if (chk_hwnds[0]) |h| _ = SendMessageW(h, BM_SETCHECK, 1, 0);
    }
    if (pending.ignore_english) {
        if (chk_hwnds[1]) |h| _ = SendMessageW(h, BM_SETCHECK, 1, 0);
    }
    if (pending.enable_middle_mouse) {
        if (chk_hwnds[2]) |h| _ = SendMessageW(h, BM_SETCHECK, 1, 0);
    }
    if (pending.autostart) {
        if (chk_hwnds[3]) |h| _ = SendMessageW(h, BM_SETCHECK, 1, 0);
    }

    const names = [_][]const u8{
        lang.t("Convert  abc <-> FA", "تبدیل  abc <-> فارسی"),
        lang.t("Reverse text (abc->cba)", "معکوس متن (سلام -> مالس)"),
        lang.t("Case     abc <-> ABC", "بزرگی  abc <-> ABC"),
        lang.t("Search in Google", "جستجو در گوگل"),
        lang.t("Translate", "ترجمه"),
        lang.t("QR Code", "کیوآر کد"),
    };

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const y: i32 = @intCast(140 + i * 34);
        _ = addControl(hWnd, btnClsW, lang.t("Change Key", "تغییر کلید"), BS_OWNERDRAW, 20, y, 100, 28, BTN_CHANGE_BASE + i);
        _ = addControl(hWnd, stcClsW, names[i], 0, 130, y + 5, 200, 22, 0);
        label_hwnds[i] = addControl(hWnd, stcClsW, "", 0, 350, y + 5, 90, 22, 3001 + i);
        refreshLabel(i, allocator);
    }

    lang_btn = addControl(hWnd, btnClsW, langLabel(), BS_OWNERDRAW, 20, 360, 190, 34, ID_LANG);
    _ = addControl(hWnd, btnClsW, lang.t("OK / Save", "تأیید / ذخیره"), BS_OWNERDRAW, 225, 360, 120, 34, ID_OK);
    _ = addControl(hWnd, btnClsW, lang.t("Close", "بستن"), BS_OWNERDRAW, 360, 360, 80, 34, ID_CLOSE);

    _ = addControl(hWnd, stcClsW, lang.t("Programmer: Nikan Rayan 💜", "برنامه‌نویس: نیکان رایان 💜"), 0, 20, 460, 420, 24, 0);

    _ = ShowWindow(hWnd, SW_SHOW);
    _ = UpdateWindow(hWnd);
}
