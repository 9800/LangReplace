const std = @import("std");
const windows = std.os.windows;
const converter = @import("converter.zig");

const HINTERNET = ?*anyopaque;
const BOOL = windows.BOOL;

extern "winhttp" fn WinHttpOpen(a: ?[*:0]const u16, b: u32, c: ?[*:0]const u16, d: ?[*:0]const u16, e: u32) callconv(windows.WINAPI) HINTERNET;
extern "winhttp" fn WinHttpConnect(a: HINTERNET, b: [*:0]const u16, c: u16, d: u32) callconv(windows.WINAPI) HINTERNET;
extern "winhttp" fn WinHttpOpenRequest(a: HINTERNET, b: [*:0]const u16, c: [*:0]const u16, d: ?[*:0]const u16, e: ?[*:0]const u16, f: ?*const [*:0]const u16, g: u32) callconv(windows.WINAPI) HINTERNET;
extern "winhttp" fn WinHttpSendRequest(a: HINTERNET, b: ?[*:0]const u16, c: i32, d: ?*anyopaque, e: u32, f: u32, g: usize) callconv(windows.WINAPI) BOOL;
extern "winhttp" fn WinHttpReceiveResponse(a: HINTERNET, b: ?*anyopaque) callconv(windows.WINAPI) BOOL;
extern "winhttp" fn WinHttpReadData(a: HINTERNET, b: *anyopaque, c: u32, d: *u32) callconv(windows.WINAPI) BOOL;
extern "winhttp" fn WinHttpCloseHandle(a: HINTERNET) callconv(windows.WINAPI) BOOL;

const WINHTTP_FLAG_SECURE: u32 = 0x00800000;
const getW = std.unicode.utf8ToUtf16LeStringLiteral("GET");
const agentW = std.unicode.utf8ToUtf16LeStringLiteral("LangReplace");

fn logWrite(msg: []const u8) void {
    var file = std.fs.cwd().openFile("langreplace_debug.log", .{ .mode = .write_only }) catch
        (std.fs.cwd().createFile("langreplace_debug.log", .{}) catch return);
    defer file.close();
    file.seekFromEnd(0) catch return;
    file.writeAll(msg) catch return;
    file.writeAll("\r\n") catch return;
}

fn toWideZ(allocator: std.mem.Allocator, s: []const u8) ?[:0]u16 {
    const w = std.unicode.utf8ToUtf16LeAlloc(allocator, s) catch return null;
    defer allocator.free(w);
    const z = allocator.alloc(u16, w.len + 1) catch return null;
    @memcpy(z[0..w.len], w);
    z[w.len] = 0;
    return z[0..w.len :0];
}

pub fn urlEncode(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    const hex = "0123456789ABCDEF";
    var out = std.ArrayList(u8).init(allocator);
    errdefer out.deinit();
    for (s) |b| {
        if (std.ascii.isAlphanumeric(b) or b == '-' or b == '_' or b == '.' or b == '~') {
            try out.append(b);
        } else {
            try out.append('%');
            try out.append(hex[b >> 4]);
            try out.append(hex[b & 15]);
        }
    }
    return out.toOwnedSlice();
}

fn httpGet(host: []const u8, path: []const u8, allocator: std.mem.Allocator) ?[]u8 {
    const hostW = toWideZ(allocator, host) orelse return null;
    defer allocator.free(hostW);
    const pathW = toWideZ(allocator, path) orelse return null;
    defer allocator.free(pathW);

    const hSession = WinHttpOpen(agentW, 0, null, null, 0) orelse {
        logWrite("HTTP: WinHttpOpen failed");
        return null;
    };
    defer _ = WinHttpCloseHandle(hSession);

    const hConnect = WinHttpConnect(hSession, hostW, 443, 0) orelse {
        logWrite("HTTP: connect failed");
        return null;
    };
    defer _ = WinHttpCloseHandle(hConnect);

    const hRequest = WinHttpOpenRequest(hConnect, getW, pathW, null, null, null, WINHTTP_FLAG_SECURE) orelse {
        logWrite("HTTP: openRequest failed");
        return null;
    };
    defer _ = WinHttpCloseHandle(hRequest);

    if (WinHttpSendRequest(hRequest, null, 0, null, 0, 0, 0) == 0) {
        logWrite("HTTP: send failed");
        return null;
    }
    if (WinHttpReceiveResponse(hRequest, null) == 0) {
        logWrite("HTTP: receive failed");
        return null;
    }

    var out = std.ArrayList(u8).init(allocator);
    errdefer out.deinit();
    var buf: [4096]u8 = undefined;
    while (true) {
        var read: u32 = 0;
        if (WinHttpReadData(hRequest, &buf, buf.len, &read) == 0) {
            logWrite("HTTP: read failed");
            return null;
        }
        if (read == 0) break;
        out.appendSlice(buf[0..read]) catch return null;
    }
    return out.toOwnedSlice() catch null;
}

fn logBody(prefix: []const u8, body: []const u8) void {
    var buf: [300]u8 = undefined;
    const n = @min(body.len, 200);
    const m = std.fmt.bufPrint(&buf, "{s}: {s}", .{ prefix, body[0..n] }) catch return;
    logWrite(m);
}

// ===== موتور ۱: گوگل =====
fn translateGoogle(text: []const u8, allocator: std.mem.Allocator) ?[]u8 {
    const layout = converter.detectLayout(text);
    const target = if (layout == .persian) "en" else "fa";

    const q = urlEncode(allocator, text) catch return null;
    defer allocator.free(q);

    const path = std.fmt.allocPrint(
        allocator,
        "/translate_a/single?client=gtx&sl=auto&tl={s}&dt=t&q={s}",
        .{ target, q },
    ) catch return null;
    defer allocator.free(path);

    logWrite("TR-GOOGLE: requesting...");
    const resp = httpGet("translate.googleapis.com", path, allocator) orelse return null;
    defer allocator.free(resp);

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, resp, .{}) catch {
        logBody("TR-GOOGLE: parse failed", resp);
        return null;
    };
    defer parsed.deinit();

    var out = std.ArrayList(u8).init(allocator);
    errdefer out.deinit();

    const root = parsed.value;
    if (root == .array) {
        for (root.array.items) |seg| {
            if (seg == .array and seg.array.items.len > 0) {
                const first = seg.array.items[0];
                if (first == .string) {
                    out.appendSlice(first.string) catch return null;
                }
            }
        }
    }

    if (out.items.len == 0) {
        logBody("TR-GOOGLE: empty result", resp);
        return null;
    }
    logWrite("TR-GOOGLE: ok");
    return out.toOwnedSlice() catch null;
}

// ===== موتور ۲: MyMemory (fallback) =====
fn translateMyMemory(text: []const u8, allocator: std.mem.Allocator) ?[]u8 {
    const layout = converter.detectLayout(text);
    const pair = if (layout == .persian) "fa|en" else "en|fa";

    const q = urlEncode(allocator, text) catch return null;
    defer allocator.free(q);
    const p = urlEncode(allocator, pair) catch return null;
    defer allocator.free(p);

    const path = std.fmt.allocPrint(allocator, "/get?q={s}&langpair={s}", .{ q, p }) catch return null;
    defer allocator.free(path);

    logWrite("TR-MYMEMORY: requesting...");
    const resp = httpGet("api.mymemory.translated.net", path, allocator) orelse return null;
    defer allocator.free(resp);

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, resp, .{}) catch {
        logBody("TR-MYMEMORY: parse failed", resp);
        return null;
    };
    defer parsed.deinit();

    const root = parsed.value;
    if (root == .object) {
        if (root.object.get("responseData")) |rd| {
            if (rd == .object) {
                if (rd.object.get("translatedText")) |tt| {
                    if (tt == .string and tt.string.len > 0) {
                        logWrite("TR-MYMEMORY: ok");
                        return allocator.dupe(u8, tt.string) catch null;
                    }
                }
            }
        }
    }
    logBody("TR-MYMEMORY: bad shape", resp);
    return null;
}

// ✅ ترجمه با fallback خودکار
pub fn translate(text: []const u8, allocator: std.mem.Allocator) ?[]u8 {
    return translateGoogle(text, allocator) orelse translateMyMemory(text, allocator);
}
