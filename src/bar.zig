const std = @import("std");
const windows = std.os.windows;
const config = @import("config.zig");
const hotkey = @import("hotkey.zig");
const clipboard = @import("clipboard.zig");
const lang = @import("lang.zig");

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
const BAR_H: i32 = 146;
const SEG_W: i32 = 56;
const SEG_Y: i32 = 98;
const BAR_TIMER: usize = 777;

const ID_NOTE: usize = 9200;
const ID_BTN_COPY: usize = 9201;
const ID_BTN_PASTE: usize = 9202;
const ID_BTN_SAVE: usize = 9203;

const WM_ERASEBKGND: UINT = 0x0014;
const WM_PAINT: UINT = 0x000F;
const WM_LBUTTONDOWN: UINT = 0x0201;
const WM_NCLBUTTONDOWN: UINT = 0x00A1;
const WM_TIMER: UINT = 0x0113;
const WM_COMMAND: UINT = 0x0111;
const WM_DRAWITEM: UINT = 0x002B;
const HTCAPTION: LRESULT = 2;
const WS_POPUP: DWORD = 0x80000000;
const WS_VISIBLE: DWORD = 0x10000000;
const WS_CHILD: DWORD = 0x40000000;
const WS_VSCROLL: DWORD = 0x200000;
const ES_MULTILINE: DWORD = 0x4;
const ES_AUTOVSCROLL: DWORD = 0x40;
const ES_WANTRETURN: DWORD = 0x1000;
const BS_OWNERDRAW: DWORD = 0xB;
const EM_SETSEL: UINT = 0x00B1;
const EM_REPLACESEL: UINT = 0x00C2;
const WS_EX_TOPMOST: DWORD = 0x8;
const WS_EX_TOOLWINDOW: DWORD = 0x80;
const WS_EX_CLIENTEDGE: DWORD = 0x200;
const SW_HIDE: i32 = 0;
const SW_SHOW: i32 = 5;
const DT_CENTER: u32 = 0x1;
const DT_VCENTER: u32 = 0x4;
const DT_SINGLELINE: u32 = 0x20;
const WM_INPUTLANGCHANGEREQUEST: UINT = 0x0050;
const KEYEVENTF_EXTENDEDKEY: DWORD = 0x0001;
const KEYEVENTF_KEYUP: DWORD = 0x0002;

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
extern "user32" fn SendMessageW(hWnd: HWND, Msg: UINT, w: WPARAM, l: LPARAM) callconv(windows.WINAPI) LRESULT;
extern "user32" fn ReleaseCapture() callconv(windows.WINAPI) BOOL;
extern "user32" fn BeginPaint(hWnd: HWND, ps: *PAINTSTRUCT) callconv(windows.WINAPI) HDC;
extern "user32" fn EndPaint(hWnd: HWND, ps: *const PAINTSTRUCT) callconv(windows.WINAPI) BOOL;
extern "user32" fn FillRect(hdc: HDC, r: *const windows.RECT, b: HBRUSH) callconv(windows.WINAPI) BOOL;
extern "user32" fn FrameRect(hdc: HDC, r: *const windows.RECT, b: HBRUSH) callconv(windows.WINAPI) BOOL;
extern "user32" fn DrawTextW(hdc: HDC, s: [*]const u16, c: i32, r: *windows.RECT, fmt: u32) callconv(windows.WINAPI) i32;
extern "user32" fn SetWindowRgn(hWnd: HWND, hRgn: HRGN, b: BOOL) callconv(windows.WINAPI) BOOL;
extern "user32" fn SendInput(c: UINT, p: *INPUT, size: i32) callconv(windows.WINAPI) UINT;
extern "user32" fn MapVirtualKeyW(code: u32, mapType: u32) callconv(windows.WINAPI) u32;
extern "user32" fn GetWindowTextW(hWnd: HWND, s: [*]u16, c: i32) callconv(windows.WINAPI) i32;
extern "user32" fn GetWindowTextLengthW(hWnd: HWND) callconv(windows.WINAPI) i32;
extern "user32" fn SetWindowTextW(hWnd: HWND, s: [*:0]const u16) callconv(windows.WINAPI) BOOL;
extern "kernel32" fn GetModuleFileNameW(h: ?windows.HMODULE, p: [*]u16, n: DWORD) callconv(windows.WINAPI) DWORD;
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

const KEYBDINPUT = extern struct { wVk: u16, wScan: u16, dwFlags: DWORD, time: DWORD, dwExtraInfo: usize };
const INPUT_U = extern union { ki: KEYBDINPUT, pad: [32]u8 };
const INPUT = extern struct { type: DWORD, u: INPUT_U };

const barClsW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplaceBar");
const editClsW = std.unicode.utf8ToUtf16LeStringLiteral("EDIT");
const btnClsW = std.unicode.utf8ToUtf16LeStringLiteral("BUTTON");
const klidFaW = std.unicode.utf8ToUtf16LeStringLiteral("00000429");
const klidEnW = std.unicode.utf8ToUtf16LeStringLiteral("00000409");

var bar_hwnd: ?HWND = null;
var note_hwnd: ?HWND = null;
var g_main_hwnd: ?HWND = null;
var g_enabled: bool = true;
var last_states: [6]bool = .{ false, false, false, false, false, false };

fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}
const COL_BAR = rgb(205, 220, 240);
const COL_LABEL = rgb(40, 60, 140);
const COL_ON = rgb(110, 200, 90);
const COL_OFF = rgb(185, 185, 185);
const COL_OFFLR = rgb(220, 90, 80);
const COL_SEG = rgb(235, 242, 252);
const COL_COPY = rgb(33, 150, 243);
const COL_PASTE = rgb(124, 77, 255);
const COL_SAVE = rgb(46, 175, 110);
const COL_WHITE = rgb(255, 255, 255);

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
    const scan: u16 = @intCast(MapVirtualKeyW(vk, 0));
    const ext: DWORD = if (vk == 0x2D or vk == 0x90) KEYEVENTF_EXTENDEDKEY else 0;

    var d: [1]INPUT = .{.{ .type = 1, .u = .{ .ki = .{ .wVk = vk, .wScan = scan, .dwFlags = ext, .time = 0, .dwExtraInfo = 0 } } }};
    _ = SendInput(1, &d[0], @sizeOf(INPUT));
    std.time.sleep(50 * std.time.ns_per_ms);
    var u: [1]INPUT = .{.{ .type = 1, .u = .{ .ki = .{ .wVk = vk, .wScan = scan, .dwFlags = ext | KEYEVENTF_KEYUP, .time = 0, .dwExtraInfo = 0 } } }};
    _ = SendInput(1, &u[0], @sizeOf(INPUT));
}

fn toggleLayout() void {
    const fg = GetForegroundWindow() orelse return;
    const klid: [*:0]const u16 = if (isFaLayout()) klidEnW else klidFaW;
    const hkl = LoadKeyboardLayoutW(klid, 1) orelse return;
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

// ===== یادداشت =====
fn notePath(allocator: std.mem.Allocator) []const u8 {
    var buf: [4096]u16 = undefined;
    const len = GetModuleFileNameW(null, &buf, buf.len);
    if (len == 0 or len >= buf.len) return "langreplace_note.txt";
    var last: usize = 0;
    var i: usize = 0;
    while (i < len) : (i += 1) {
        if (buf[i] == '\\' or buf[i] == '/') last = i;
    }
    if (last == 0) return "langreplace_note.txt";
    const dirU8 = std.unicode.utf16LeToUtf8Alloc(allocator, buf[0..last]) catch return "langreplace_note.txt";
    defer allocator.free(dirU8);
    return std.fmt.allocPrint(allocator, "{s}\\langreplace_note.txt", .{dirU8}) catch "langreplace_note.txt";
}

fn editTextAlloc(allocator: std.mem.Allocator) ?[]u8 {
    const h = note_hwnd orelse return null;
    const len = GetWindowTextLengthW(h);
    if (len <= 0) return null;
    const buf = allocator.alloc(u16, @as(usize, @intCast(len)) + 1) catch return null;
    defer allocator.free(buf);
    const n = GetWindowTextW(h, buf.ptr, len + 1);
    if (n <= 0) return null;
    return std.unicode.utf16LeToUtf8Alloc(allocator, buf[0..@as(usize, @intCast(n))]) catch null;
}

fn noteCopy() void {
    const allocator = std.heap.page_allocator;
    const text = editTextAlloc(allocator) orelse return;
    defer allocator.free(text);
    _ = clipboard.setClipboardText(text);
}

fn notePaste() void {
    const allocator = std.heap.page_allocator;
    const h = note_hwnd orelse return;
    // ✅ باز کردن مقدار optional
    const clip_opt = clipboard.getClipboardText(allocator) catch return;
    const clip = clip_opt orelse return;
    defer allocator.free(clip);
    const w = std.unicode.utf8ToUtf16LeAlloc(allocator, clip) catch return;
    defer allocator.free(w);
    const len = GetWindowTextLengthW(h);
    _ = SendMessageW(h, EM_SETSEL, @as(WPARAM, @intCast(len)), @as(LPARAM, @intCast(len)));
    _ = SendMessageW(h, EM_REPLACESEL, 0, @as(LPARAM, @bitCast(@intFromPtr(w.ptr))));
}

fn noteSave() void {
    const allocator = std.heap.page_allocator;
    const p = notePath(allocator);
    const text = editTextAlloc(allocator);
    defer if (text) |t| allocator.free(t);
    var f = std.fs.cwd().createFile(p, .{}) catch return;
    defer f.close();
    if (text) |t| {
        f.writeAll(t) catch return;
    }
}

fn loadNote() void {
    const allocator = std.heap.page_allocator;
    const h = note_hwnd orelse return;
    const p = notePath(allocator);
    const content = std.fs.cwd().readFileAlloc(allocator, p, 100000) catch return;
    defer allocator.free(content);
    const w = std.unicode.utf8ToUtf16LeAlloc(allocator, content) catch return;
    defer allocator.free(w);
    const z = allocator.alloc(u16, w.len + 1) catch return;
    defer allocator.free(z);
    @memcpy(z[0..w.len], w);
    z[w.len] = 0;
    const zs: [:0]u16 = z[0..w.len :0];
    _ = SetWindowTextW(h, zs);
}

// ===== رسم =====
fn drawIranFlag(dc: HDC, r: windows.RECT) void {
    const h = r.bottom - r.top;
    const t3 = @divTrunc(h, 3);
    const g = CreateSolidBrush(rgb(35, 159, 64));
    var gr = windows.RECT{ .left = r.left, .top = r.top, .right = r.right, .bottom = r.top + t3 };
    _ = FillRect(dc, &gr, g);
    _ = DeleteObject(g);
    const wh = CreateSolidBrush(rgb(255, 255, 255));
    var wr = windows.RECT{ .left = r.left, .top = r.top + t3, .right = r.right, .bottom = r.top + 2 * t3 };
    _ = FillRect(dc, &wr, wh);
    _ = DeleteObject(wh);
    const rd = CreateSolidBrush(rgb(218, 53, 60));
    var rr = windows.RECT{ .left = r.left, .top = r.top + 2 * t3, .right = r.right, .bottom = r.bottom };
    _ = FillRect(dc, &rr, rd);
    _ = DeleteObject(rd);
}

fn drawUsFlag(dc: HDC, r: windows.RECT) void {
    const h = r.bottom - r.top;
    const w = r.right - r.left;
    const stripes: i32 = 7;
    const sh = @divTrunc(h, stripes);
    var i: i32 = 0;
    while (i < stripes) : (i += 1) {
        const col = if (@rem(i, 2) == 0) rgb(179, 25, 66) else rgb(255, 255, 255);
        const br = CreateSolidBrush(col);
        var sr = windows.RECT{ .left = r.left, .top = r.top + i * sh, .right = r.right, .bottom = r.top + (i + 1) * sh };
        if (i == stripes - 1) sr.bottom = r.bottom;
        _ = FillRect(dc, &sr, br);
        _ = DeleteObject(br);
    }
    const bl = CreateSolidBrush(rgb(60, 59, 110));
    var cr = windows.RECT{ .left = r.left, .top = r.top, .right = r.left + @divTrunc(w * 2, 5), .bottom = r.top + @divTrunc(h, 2) };
    _ = FillRect(dc, &cr, bl);
    _ = DeleteObject(bl);
}

fn barProc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(windows.WINAPI) LRESULT {
    switch (Msg) {
        WM_ERASEBKGND => return 1,
        WM_COMMAND => {
            const id = wParam & 0xFFFF;
            if (id == ID_BTN_COPY) {
                noteCopy();
                return 0;
            }
            if (id == ID_BTN_PASTE) {
                notePaste();
                return 0;
            }
            if (id == ID_BTN_SAVE) {
                noteSave();
                return 0;
            }
            return 0;
        },
        WM_DRAWITEM => {
            const dis: *DRAWITEMSTRUCT = @ptrFromInt(@as(usize, @bitCast(lParam)));
            if (dis.hDC) |dc| {
                const id = dis.CtlID;
                const fill = if (id == ID_BTN_COPY) COL_COPY else if (id == ID_BTN_PASTE) COL_PASTE else COL_SAVE;
                const br = CreateSolidBrush(fill);
                const pen = CreatePen(0, 2, fill);
                const oldB = SelectObject(dc, br);
                const oldP = SelectObject(dc, pen);
                const r = dis.rcItem;
                _ = RoundRect(dc, r.left, r.top, r.right, r.bottom, 10, 10);
                var buf: [32]u16 = undefined;
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
        WM_TIMER => {
            var changed = false;
            var i: usize = 0;
            while (i < 6) : (i += 1) {
                const cur = isOn(i);
                if (cur != last_states[i]) {
                    last_states[i] = cur;
                    changed = true;
                }
            }
            if (changed) _ = InvalidateRect(hWnd, null, 0);
            return 0;
        },
        WM_PAINT => {
            var ps: PAINTSTRUCT = undefined;
            const dc = BeginPaint(hWnd, &ps);
            if (dc) |hdc| {
                var bgr = windows.RECT{ .left = 0, .top = 0, .right = BAR_W, .bottom = BAR_H };
                const bb = CreateSolidBrush(COL_BAR);
                _ = FillRect(hdc, &bgr, bb);
                _ = DeleteObject(bb);

                var i: usize = 0;
                while (i < 6) : (i += 1) {
                    const x: i32 = @intCast(4 + i * (SEG_W + 2));
                    var sr = windows.RECT{ .left = x, .top = SEG_Y + 3, .right = x + SEG_W, .bottom = SEG_Y + 41 };
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
                    var tr = windows.RECT{ .left = x, .top = SEG_Y + 4, .right = x + SEG_W, .bottom = SEG_Y + 20 };
                    _ = DrawTextW(hdc, &buf, -1, &tr, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

                    if (i == 0) {
                        const fr = windows.RECT{ .left = x + 5, .top = SEG_Y + 24, .right = x + 27, .bottom = SEG_Y + 37 };
                        if (isFaLayout()) {
                            drawIranFlag(hdc, fr);
                        } else {
                            drawUsFlag(hdc, fr);
                        }
                        const on = isOn(i);
                        var lr = windows.RECT{ .left = x + 32, .top = SEG_Y + 25, .right = x + SEG_W - 6, .bottom = SEG_Y + 36 };
                        const lb = CreateSolidBrush(if (on) COL_ON else COL_OFF);
                        _ = FillRect(hdc, &lr, lb);
                        _ = DeleteObject(lb);
                        const lb2 = CreateSolidBrush(rgb(120, 130, 150));
                        _ = FrameRect(hdc, &lr, lb2);
                        _ = DeleteObject(lb2);
                    } else {
                        const on = isOn(i);
                        const ledCol = if (on) COL_ON else (if (i == 5) COL_OFFLR else COL_OFF);
                        var lr = windows.RECT{ .left = x + 8, .top = SEG_Y + 25, .right = x + SEG_W - 8, .bottom = SEG_Y + 36 };
                        const lb = CreateSolidBrush(ledCol);
                        _ = FillRect(hdc, &lr, lb);
                        _ = DeleteObject(lb);
                        const lb2 = CreateSolidBrush(rgb(120, 130, 150));
                        _ = FrameRect(hdc, &lr, lb2);
                        _ = DeleteObject(lb2);
                    }
                }
            }
            _ = EndPaint(hWnd, &ps);
            return 0;
        },
        WM_LBUTTONDOWN => {
            const x = @as(i32, @intCast(@as(i16, @truncate(lParam))));
            const y = @as(i32, @intCast(@as(i16, @truncate(lParam >> 16))));
            if (y >= SEG_Y and x >= 4) {
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
                    _ = InvalidateRect(hWnd, null, 0);
                }
            }
            _ = ReleaseCapture();
            _ = SendMessageW(hWnd, WM_NCLBUTTONDOWN, @as(WPARAM, @intCast(HTCAPTION)), lParam);
            return 0;
        },
        else => return DefWindowProcW(hWnd, Msg, wParam, lParam),
    }
}

pub fn createBar(hInst: ?HINSTANCE, mainHwnd: ?HWND) void {
    g_main_hwnd = mainHwnd;

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        last_states[i] = isOn(i);
    }

    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW), .style = 0, .lpfnWndProc = barProc,
        .cbClsExtra = 0, .cbWndExtra = 0, .hInstance = hInst, .hIcon = null,
        .hCursor = null, .hbrBackground = null, .lpszMenuName = null,
        .lpszClassName = barClsW, .hIconSm = null,
    };
    _ = RegisterClassExW(&wc);

    const titleW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplace Bar");

    const hWnd = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_TOOLWINDOW, barClsW, titleW,
        WS_POPUP | WS_VISIBLE, 120, 120, BAR_W, BAR_H,
        null, null, hInst, null,
    ) orelse return;
    bar_hwnd = hWnd;

    const rgn = CreateRoundRectRgn(0, 0, BAR_W + 1, BAR_H + 1, 14, 14) orelse return;
    _ = SetWindowRgn(hWnd, rgn, 1);

    const emptyW = std.unicode.utf8ToUtf16LeStringLiteral("");
    note_hwnd = CreateWindowExW(
        WS_EX_CLIENTEDGE, editClsW, emptyW,
        WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE | ES_AUTOVSCROLL | ES_WANTRETURN,
        6, 6, BAR_W - 12, 62,
        hWnd, @ptrFromInt(ID_NOTE), hInst, null,
    );

    const copyW = std.unicode.utf8ToUtf16LeStringLiteral("Copy");
    const pasteW = std.unicode.utf8ToUtf16LeStringLiteral("Paste");
    const saveW = std.unicode.utf8ToUtf16LeStringLiteral("Save");
    _ = CreateWindowExW(0, btnClsW, copyW, WS_CHILD | WS_VISIBLE | BS_OWNERDRAW, 6, 72, 110, 22, hWnd, @ptrFromInt(ID_BTN_COPY), hInst, null);
    _ = CreateWindowExW(0, btnClsW, pasteW, WS_CHILD | WS_VISIBLE | BS_OWNERDRAW, 122, 72, 110, 22, hWnd, @ptrFromInt(ID_BTN_PASTE), hInst, null);
    _ = CreateWindowExW(0, btnClsW, saveW, WS_CHILD | WS_VISIBLE | BS_OWNERDRAW, 238, 72, 112, 22, hWnd, @ptrFromInt(ID_BTN_SAVE), hInst, null);

    loadNote();

    _ = SetTimer(hWnd, BAR_TIMER, 500, null);
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
