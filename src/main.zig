const std = @import("std");
const windows = std.os.windows;

const tray = @import("tray.zig");
const hotkey = @import("hotkey.zig");
const clipboard = @import("clipboard.zig");
const converter = @import("converter.zig");
const search = @import("search.zig");
const keyboard = @import("keyboard.zig");
const translate = @import("translate.zig");
const config = @import("config.zig");
const settings_ui = @import("settings_ui.zig");
const lang = @import("lang.zig");

const HWND = windows.HWND;
const UINT = windows.UINT;
const WPARAM = windows.WPARAM;
const LPARAM = windows.LPARAM;
const LRESULT = windows.LRESULT;
const HINSTANCE = windows.HINSTANCE;
const HICON = windows.HICON;
const DWORD = windows.DWORD;
const BOOL = windows.BOOL;

const POINT = extern struct { x: i32, y: i32 };

const MSG = extern struct {
    hwnd: ?HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
};

const classNameW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceWindow");
const windowNameW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplace");

extern "user32" fn RegisterClassExW(wndClassEx: *const WNDCLASSEXW) callconv(windows.WINAPI) u16;
extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: windows.LPCWSTR,
    lpWindowName: windows.LPCWSTR,
    dwStyle: DWORD,
    X: i32, Y: i32, nWidth: i32, nHeight: i32,
    hWndParent: ?HWND,
    hMenu: ?windows.HMENU,
    hInstance: ?HINSTANCE,
    lpParam: ?*anyopaque,
) callconv(windows.WINAPI) ?HWND;
extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(windows.WINAPI) BOOL;
extern "user32" fn UpdateWindow(hWnd: HWND) callconv(windows.WINAPI) BOOL;
extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(windows.WINAPI) BOOL;
extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(windows.WINAPI) BOOL;
extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(windows.WINAPI) LRESULT;
extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(windows.WINAPI) void;
extern "user32" fn MessageBoxW(hWnd: ?HWND, lpText: [*:0]const u16, lpCaption: [*:0]const u16, uType: UINT) callconv(windows.WINAPI) i32;
extern "user32" fn LoadIconW(hInstance: ?HINSTANCE, lpIconName: usize) callconv(windows.WINAPI) ?HICON;
extern "user32" fn GetCursorPos(lpPoint: *POINT) callconv(windows.WINAPI) BOOL;

const WNDCLASSEXW = extern struct {
    cbSize: UINT,
    style: UINT,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(windows.WINAPI) LRESULT,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: ?HINSTANCE,
    hIcon: ?HICON,
    hCursor: ?windows.HCURSOR,
    hbrBackground: ?windows.HBRUSH,
    lpszMenuName: ?windows.LPCWSTR,
    lpszClassName: windows.LPCWSTR,
    hIconSm: ?HICON,
};

const WM_HOTKEY: UINT = 0x0312;
const WM_COMMAND: UINT = 0x0111;
const WM_DESTROY: UINT = 0x0002;
const SW_HIDE: i32 = 0;
const WS_OVERLAPPEDWINDOW: DWORD = 0x00CF0000;
const CW_USEDEFAULT: i32 = @as(i32, @bitCast(@as(u32, 0x80000000)));

const MB_TOP: UINT = 0x40 | 0x00001000 | 0x00010000;
const IDYES: i32 = 6;

var g_hInstance: ?HINSTANCE = null;
var g_tray: ?tray.TrayManager = null;
var g_icon: ?HICON = null;

fn notify(msg: []const u8) void {
    if (g_tray) |*t| t.showBalloon("LangReplace", msg);
}

fn toWideZ(allocator: std.mem.Allocator, s: []const u8) ?[:0]u16 {
    const w = std.unicode.utf8ToUtf16LeAlloc(allocator, s) catch return null;
    defer allocator.free(w);
    const z = allocator.alloc(u16, w.len + 1) catch return null;
    @memcpy(z[0..w.len], w);
    z[w.len] = 0;
    return z[0..w.len :0];
}

fn logWrite(msg: []const u8) void {
    var file = std.fs.cwd().openFile("langreplace_debug.log", .{ .mode = .write_only }) catch
        (std.fs.cwd().createFile("langreplace_debug.log", .{}) catch return);
    defer file.close();
    file.seekFromEnd(0) catch return;
    file.writeAll(msg) catch return;
    file.writeAll("\r\n") catch return;
}

fn loadAppIcon() ?HICON {
    return LoadIconW(g_hInstance, 1) orelse LoadIconW(null, 32512);
}

fn waitForClipboardChange(old_seq: DWORD) bool {
    var i: u32 = 0;
    while (i < 50) : (i += 1) {
        if (clipboard.getSequence() != old_seq) return true;
        std.time.sleep(10 * std.time.ns_per_ms);
    }
    return false;
}

fn convertByMode(text: []const u8, force_english: bool, allocator: std.mem.Allocator) ?[]u8 {
    if (force_english) return converter.convertText(text, .persian, .english, allocator) catch null;
    const layout = converter.detectLayout(text);
    const target: converter.KeyboardLayout = if (layout == .persian) .english else .persian;
    return converter.convertText(text, layout, target, allocator) catch null;
}

// ✅ تغییر بزرگی/کوچکی حروف (abc <-> ABC)
fn swapCaseText(text: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var out = std.ArrayList(u8).init(allocator);
    errdefer out.deinit();
    for (text) |b| {
        if (b >= 'a' and b <= 'z') {
            try out.append(b - 32);
        } else if (b >= 'A' and b <= 'Z') {
            try out.append(b + 32);
        } else {
            try out.append(b);
        }
    }
    return out.toOwnedSlice();
}

fn readLineNow(allocator: std.mem.Allocator) ?[]u8 {
    keyboard.selectCurrentLine();
    std.time.sleep(30 * std.time.ns_per_ms);
    const seq = clipboard.getSequence();
    keyboard.simulateCtrlCombo(keyboard.VK_C);
    if (!waitForClipboardChange(seq)) return null;
    return clipboard.getClipboardText(allocator) catch null;
}

fn writeOverSelection(converted: []const u8, allocator: std.mem.Allocator) void {
    keyboard.deleteSelection();
    std.time.sleep(20 * std.time.ns_per_ms);
    keyboard.typeUnicodeText(converted, allocator);
}

fn doConvert(id: hotkey.HotkeyId, text: []const u8, allocator: std.mem.Allocator) ?[]u8 {
    if (id == .convert_case) return swapCaseText(text, allocator) catch null;
    return convertByMode(text, id == .convert_reverse, allocator);
}

fn handleHotkey(id: hotkey.HotkeyId) void {
    const allocator = std.heap.page_allocator;

    switch (id) {
        .search_google => {
            const text = readLineNow(allocator) orelse return;
            defer allocator.free(text);
            keyboard.collapseSelection();
            _ = search.openGoogleSearch(text, allocator);
            return;
        },
        .translate => {
            logWrite("=== Ctrl+T translate ===");
            const text = readLineNow(allocator) orelse {
                notify(lang.t("✗ No text found", "✗ متنی پیدا نشد"));
                return;
            };
            defer allocator.free(text);
            keyboard.collapseSelection();
            if (text.len == 0) return;

            const result = translate.translate(text, allocator) orelse {
                notify(lang.t("✗ Translation failed", "✗ ترجمه انجام نشد"));
                return;
            };
            defer allocator.free(result);

            logWrite("TRANSLATE: ok");
            const bodyW = toWideZ(allocator, result) orelse return;
            defer allocator.free(bodyW);
            const titleW = toWideZ(allocator, lang.t("LangReplace - Translate", "LangReplace - ترجمه")) orelse return;
            defer allocator.free(titleW);
            _ = MessageBoxW(null, bodyW, titleW, MB_TOP);
            return;
        },
        .qr_code => {
            logWrite("=== Ctrl+M QR ===");
            const text = readLineNow(allocator) orelse return;
            defer allocator.free(text);
            keyboard.collapseSelection();
            if (text.len == 0) return;
            const q = translate.urlEncode(allocator, text) catch return;
            defer allocator.free(q);
            const url = std.fmt.allocPrint(allocator, "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data={s}", .{q}) catch return;
            defer allocator.free(url);
            _ = search.openUrl(url, allocator);
            return;
        },
        else => {},
    }

    logWrite("=== convert pressed ===");

    const text = readLineNow(allocator) orelse {
        keyboard.selectPreviousWord();
        std.time.sleep(30 * std.time.ns_per_ms);
        const seqC = clipboard.getSequence();
        keyboard.simulateCtrlCombo(keyboard.VK_C);
        if (waitForClipboardChange(seqC)) {
            const t3 = clipboard.getClipboardText(allocator) catch return;
            if (t3) |t| {
                defer allocator.free(t);
                logWrite("PATH-WORD");
                if (t.len == 0) return;
                const converted = doConvert(id, t, allocator) orelse return;
                defer allocator.free(converted);
                if (std.mem.eql(u8, converted, t)) return;
                writeOverSelection(converted, allocator);
                notify(lang.t("✓ Converted", "✓ تبدیل شد"));
                return;
            }
        }
        keyboard.collapseSelection();
        logWrite("NONE");
        notify(lang.t("✗ No text found", "✗ متنی پیدا نشد"));
        return;
    };
    defer allocator.free(text);

    logWrite("PATH-LINE");

    if (text.len == 0) {
        keyboard.collapseSelection();
        return;
    }

    const converted = doConvert(id, text, allocator) orelse return;
    defer allocator.free(converted);

    if (std.mem.eql(u8, converted, text)) {
        keyboard.collapseSelection();
        logWrite("SKIP: same");
        return;
    }

    writeOverSelection(converted, allocator);
    std.time.sleep(150 * std.time.ns_per_ms);

    const line_now = readLineNow(allocator) orelse {
        logWrite("VERIFY: null");
        notify(lang.t("✓ Converted", "✓ تبدیل شد"));
        return;
    };
    defer allocator.free(line_now);

    if (std.mem.eql(u8, line_now, converted)) {
        logWrite("VERIFY: match");
        notify(lang.t("✓ Converted", "✓ تبدیل شد"));
        return;
    }

    logWrite("VERIFY: mismatch -> rewrite");
    writeOverSelection(converted, allocator);
    notify(lang.t("✓ Converted (fallback)", "✓ تبدیل شد (پشتیبان)"));
}

fn handleMenuCommand(cmd: usize, hWnd: HWND) void {
    switch (cmd) {
        tray.MENU_ID_EXIT => {
            if (g_tray) |*t| t.cleanup();
            hotkey.unregisterHotkeys(hWnd);
            PostQuitMessage(0);
        },
        tray.MENU_ID_SETTINGS => {
            settings_ui.openSettings(g_hInstance, hWnd);
        },
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
            const mouse_msg: UINT = @intCast(lParam & 0xFFFF);
            if (mouse_msg == tray.WM_RBUTTONUP) {
                if (g_tray) |*t| {
                    var pt: POINT = .{ .x = 0, .y = 0 };
                    _ = GetCursorPos(&pt);
                    const cmd = t.showContextMenu(pt.x, pt.y);
                    if (cmd != 0) handleMenuCommand(cmd, hWnd);
                }
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

// ✅ انتخاب زبان در اولین اجرا
fn firstRunLanguage() void {
    if (config.fileExists()) return;
    const q = std.unicode.utf8ToUtf16LeStringLiteral("Welcome to LangReplace!\nChoose UI language / زبان رابط را انتخاب کنید:\n\nYes = فارسی\nNo = English");
    const c = std.unicode.utf8ToUtf16LeStringLiteral("LangReplace");
    const r = MessageBoxW(null, q, c, 0x20 | 0x4 | MB_TOP);
    config.g_config.language = if (r == IDYES) 1 else 0;
    config.save(config.g_config, std.heap.page_allocator);
}

pub fn main() !void {
    const hModule = windows.kernel32.GetModuleHandleW(null);
    g_hInstance = @ptrCast(hModule);
    g_icon = loadAppIcon();
    config.g_config = config.load(std.heap.page_allocator);
    firstRunLanguage();

    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = 0,
        .lpfnWndProc = windowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = g_hInstance,
        .hIcon = g_icon,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = classNameW,
        .hIconSm = g_icon,
    };

    _ = RegisterClassExW(&wc);

    const hWnd = CreateWindowExW(
        0, classNameW, windowNameW, WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        null, null, g_hInstance, null,
    ) orelse return error.WindowCreationFailed;

    g_tray = try tray.TrayManager.init(hWnd, g_icon);
    _ = hotkey.registerHotkeys(hWnd, config.g_config);

    _ = ShowWindow(hWnd, SW_HIDE);
    _ = UpdateWindow(hWnd);

    var msg: MSG = undefined;
    while (GetMessageW(&msg, null, 0, 0) != 0) {
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
}
