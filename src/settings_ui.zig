const std = @import("std");
const windows = std.os.windows;
const config = @import("config.zig");
const lang = @import("lang.zig");

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
const ID_LANG: usize = 2401;
const ID_PICK_FA: usize = 9001;
const ID_PICK_EN: usize = 9002;

const WS_CHILD: windows.DWORD = 0x40000000;
const WS_VISIBLE: windows.DWORD = 0x10000000;
const BS_CHECKBOX: windows.DWORD = 0x3;
const BS_PUSHBUTTON: windows.DWORD = 0x0;
const WM_CLOSE: UINT = 0x0010;
const WM_COMMAND: UINT = 0x0111;
const BM_GETCHECK: UINT = 0x00F0;
const BM_SETCHECK: UINT = 0x00F1;
const SW_SHOW: i32 = 5;
const WS_EX_TOPMOST: windows.DWORD = 0x00000008;

const PMSG = extern struct {
    hwnd: ?HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: extern struct { x: i32, y: i32 },
};

extern "user32" fn RegisterClassExW(w: *const WNDCLASSEXW) callconv(windows.WINAPI) u16;
extern "user32" fn CreateWindowExW(a: windows.DWORD, b: windows.LPCWSTR, c: windows.LPCWSTR, d: windows.DWORD, e: i32, f: i32, g: i32, h: i32, i: ?HWND, j: ?windows.HMENU, k: ?HINSTANCE, l: ?*anyopaque) callconv(windows.WINAPI) ?HWND;
extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, w: WPARAM, l: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn ShowWindow(hWnd: HWND, n: i32) callconv(windows.WINAPI) BOOL;
extern "user32" fn UpdateWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn DestroyWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn SendMessageW(hWnd: HWND, Msg: UINT, w: WPARAM, l: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn SetWindowTextW(hWnd: HWND, s: [*:0]const u16) callconv(windows.WINAPI) BOOL;
extern "user32" fn GetAsyncKeyState(v: i32) callconv(windows.WINAPI) i16;
extern "user32" fn GetMessageW(lpMsg: *PMSG, hWnd: ?HWND, a: UINT, b: UINT) callconv(windows.WINAPI) BOOL;
extern "user32" fn TranslateMessage(m: *const PMSG) callconv(windows.WINAPI) BOOL;
extern "user32" fn DispatchMessageW(m: *const PMSG) callconv(windows.WINAPI) LRESULT;

const WNDCLASSEXW = extern struct {
    cbSize: UINT, style: UINT,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(windows.WINAPI) LRESULT,
    cbClsExtra: i32, cbWndExtra: i32, hInstance: ?HINSTANCE,
    hIcon: ?windows.HICON, hCursor: ?windows.HCURSOR, hbrBackground: ?windows.HBRUSH,
    lpszMenuName: ?windows.LPCWSTR, lpszClassName: windows.LPCWSTR, hIconSm: ?windows.HICON,
};

const clsW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceSettings");
const pickClsW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceLangPick");
const btnClsW = std.unicode.utf8ToUtf16LeStringLiteral("BUTTON");
const stcClsW = std.unicode.utf8ToUtf16LeStringLiteral("STATIC");

var g_hInst: ?HINSTANCE = null;
var g_parent: ?HWND = null;
var pending: config.Config = .{};
var label_hwnds: [6]?HWND = .{ null, null, null, null, null, null };
var lang_btn: ?HWND = null;
// ✅ HWND واقعی چک‌باکس‌ها
var chk_hwnds: [3]?HWND = .{ null, null, null };
var lang_choice: i32 = -1;

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

fn addControl(parent: HWND, classW: windows.LPCWSTR, textUtf8: []const u8, style: windows.DWORD, x: i32, y: i32, w: i32, h: i32, id: usize) ?HWND {
    const allocator = std.heap.page_allocator;
    const tw = mkWide(allocator, textUtf8) orelse return null;
    defer allocator.free(tw);
    const hMenu: ?windows.HMENU = if (id == 0) null else @ptrFromInt(id);
    return CreateWindowExW(0, classW, tw, WS_CHILD | WS_VISIBLE | style, x, y, w, h, parent, hMenu, g_hInst, null);
}

// ===== پنجره انتخاب زبان (اولین اجرا) =====
fn pickProc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    switch (Msg) {
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

    const hWnd = CreateWindowExW(WS_EX_TOPMOST, pickClsW, title, 0x00CF0000, 400, 300, 400, 180, null, null, hInst, null) orelse return 0;

    const desc = mkWide(allocator, "زبان برنامه را انتخاب کنید\r\nChoose the interface language:") orelse return 0;
    defer allocator.free(desc);
    _ = CreateWindowExW(0, stcClsW, desc, WS_CHILD | WS_VISIBLE, 20, 15, 350, 40, hWnd, null, hInst, null);

    const faW = mkWide(allocator, "فارسی") orelse return 0;
    defer allocator.free(faW);
    _ = CreateWindowExW(0, btnClsW, faW, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 40, 80, 140, 45, hWnd, @ptrFromInt(ID_PICK_FA), hInst, null);

    const enW = mkWide(allocator, "English") orelse return 0;
    defer allocator.free(enW);
    _ = CreateWindowExW(0, btnClsW, enW, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 210, 80, 140, 45, hWnd, @ptrFromInt(ID_PICK_EN), hInst, null);

    _ = ShowWindow(hWnd, SW_SHOW);
    _ = UpdateWindow(hWnd);

    var msg: PMSG = undefined;
    while (lang_choice == -1 and GetMessageW(&msg, null, 0, 0) != 0) {
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
    return if (lang_choice == 1) 1 else 0;
}

// ===== پنجره تنظیمات =====
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
            if (id == ID_LANG) {
                pending.language = if (pending.language == 1) 0 else 1;
                setWide(lang_btn, langLabel());
                return 0;
            }
            if (id == ID_OK) {
                // ✅ خواندن با HWND واقعی
                if (chk_hwnds[0]) |h| pending.ignore_upper_case = (SendMessageW(h, BM_GETCHECK, 0, 0) != 0);
                if (chk_hwnds[1]) |h| pending.ignore_english = (SendMessageW(h, BM_GETCHECK, 0, 0) != 0);
                if (chk_hwnds[2]) |h| pending.enable_middle_mouse = (SendMessageW(h, BM_GETCHECK, 0, 0) != 0);
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

    const title = mkWide(allocator, lang.t("LangReplace - Settings", "LangReplace - تنظیمات")) orelse return;
    defer allocator.free(title);

    const hWnd = CreateWindowExW(0, clsW, title, 0x00CF0000, 100, 100, 460, 460, parent, null, hInst, null) orelse return;

    chk_hwnds[0] = addControl(hWnd, btnClsW, lang.t("Ignore Upper case when converting", "نادیده گرفتن بزرگی حروف هنگام تبدیل"), BS_CHECKBOX, 20, 20, 400, 24, ID_CHK_UPPER);
    chk_hwnds[1] = addControl(hWnd, btnClsW, lang.t("Ignore English when reversing text", "نادیده گرفتن انگلیسی هنگام معکوس کردن"), BS_CHECKBOX, 20, 48, 400, 24, ID_CHK_ENG);
    chk_hwnds[2] = addControl(hWnd, btnClsW, lang.t("Enable operation with mouse middle button", "فعال‌سازی با دکمه وسط موس"), BS_CHECKBOX, 20, 76, 400, 24, ID_CHK_MOUSE);

    // ✅ تیک اولیه با HWND واقعی
    if (pending.ignore_upper_case) {
        if (chk_hwnds[0]) |h| _ = SendMessageW(h, BM_SETCHECK, 1, 0);
    }
    if (pending.ignore_english) {
        if (chk_hwnds[1]) |h| _ = SendMessageW(h, BM_SETCHECK, 1, 0);
    }
    if (pending.enable_middle_mouse) {
        if (chk_hwnds[2]) |h| _ = SendMessageW(h, BM_SETCHECK, 1, 0);
    }

    const names = [_][]const u8{
        lang.t("Convert  abc <-> FA", "تبدیل  abc <-> فارسی"),
        lang.t("Reverse  FA <-> abc", "معکوس  فارسی <-> abc"),
        lang.t("Case     abc <-> ABC", "بزرگی  abc <-> ABC"),
        lang.t("Search in Google", "جستجو در گوگل"),
        lang.t("Translate", "ترجمه"),
        lang.t("QR Code", "کیوآر کد"),
    };

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const y: i32 = @intCast(110 + i * 34);
        _ = addControl(hWnd, btnClsW, lang.t("Change Key", "تغییر کلید"), BS_PUSHBUTTON, 20, y, 100, 28, BTN_CHANGE_BASE + i);
        _ = addControl(hWnd, stcClsW, names[i], 0, 130, y + 5, 200, 22, 0);
        label_hwnds[i] = addControl(hWnd, stcClsW, "", 0, 340, y + 5, 90, 22, 3001 + i);
        refreshLabel(i, allocator);
    }

    lang_btn = addControl(hWnd, btnClsW, langLabel(), BS_PUSHBUTTON, 20, 330, 200, 32, ID_LANG);
    _ = addControl(hWnd, btnClsW, lang.t("OK / Save", "تأیید / ذخیره"), BS_PUSHBUTTON, 240, 330, 120, 32, ID_OK);

    _ = ShowWindow(hWnd, SW_SHOW);
    _ = UpdateWindow(hWnd);
}
