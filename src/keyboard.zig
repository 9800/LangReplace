const std = @import("std");
const windows = std.os.windows;

const UINT = windows.UINT;
const DWORD = windows.DWORD;

const INPUT_KEYBOARD: DWORD = 1;
const KEYEVENTF_KEYUP: DWORD = 0x0002;
const KEYEVENTF_UNICODE: DWORD = 0x0004;

const VK_SHIFT: u16 = 0x10;
const VK_CONTROL: u16 = 0x11;
const VK_HOME: u16 = 0x24;
const VK_END: u16 = 0x23;
const VK_LEFT: u16 = 0x25;
const VK_RIGHT: u16 = 0x27;
const VK_DELETE: u16 = 0x2E;

pub const VK_C: u16 = 0x43;
pub const VK_V: u16 = 0x56;

const MOUSEINPUT = extern struct { dx: i32, dy: i32, mouseData: DWORD, dwFlags: DWORD, time: DWORD, dwExtraInfo: usize };
const KEYBDINPUT = extern struct { wVk: u16, wScan: u16, dwFlags: DWORD, time: DWORD, dwExtraInfo: usize };
const HARDWAREINPUT = extern struct { uMsg: DWORD, wParamL: u16, wParamH: u16 };

const INPUT_U = extern union { mi: MOUSEINPUT, ki: KEYBDINPUT, hi: HARDWAREINPUT };

const INPUT = extern struct {
    type: DWORD,
    u: INPUT_U,
};

extern "user32" fn SendInput(cInputs: UINT, pInputs: *INPUT, cbSize: i32) callconv(windows.WINAPI) UINT;

fn keyInput(vk: u16, flags: DWORD) INPUT {
    return INPUT{ .type = INPUT_KEYBOARD, .u = .{ .ki = .{ .wVk = vk, .wScan = 0, .dwFlags = flags, .time = 0, .dwExtraInfo = 0 } } };
}

fn unicodeInput(scan: u16, flags: DWORD) INPUT {
    return INPUT{ .type = INPUT_KEYBOARD, .u = .{ .ki = .{ .wVk = 0, .wScan = scan, .dwFlags = flags | KEYEVENTF_UNICODE, .time = 0, .dwExtraInfo = 0 } } };
}

pub fn simulateCtrlCombo(vk: u16) void {
    var inputs: [4]INPUT = .{
        keyInput(VK_CONTROL, 0),
        keyInput(vk, 0),
        keyInput(vk, KEYEVENTF_KEYUP),
        keyInput(VK_CONTROL, KEYEVENTF_KEYUP),
    };
    _ = SendInput(4, &inputs[0], @sizeOf(INPUT));
}

pub fn selectCurrentLine() void {
    var inputs: [6]INPUT = .{
        keyInput(VK_HOME, 0),
        keyInput(VK_HOME, KEYEVENTF_KEYUP),
        keyInput(VK_SHIFT, 0),
        keyInput(VK_END, 0),
        keyInput(VK_END, KEYEVENTF_KEYUP),
        keyInput(VK_SHIFT, KEYEVENTF_KEYUP),
    };
    _ = SendInput(6, &inputs[0], @sizeOf(INPUT));
}

// ✅ انتخاب کلمه قبلی (روش جایگزین وقتی Home/End کار نمی‌کنه)
pub fn selectPreviousWord() void {
    var inputs: [6]INPUT = .{
        keyInput(VK_CONTROL, 0),
        keyInput(VK_SHIFT, 0),
        keyInput(VK_LEFT, 0),
        keyInput(VK_LEFT, KEYEVENTF_KEYUP),
        keyInput(VK_SHIFT, KEYEVENTF_KEYUP),
        keyInput(VK_CONTROL, KEYEVENTF_KEYUP),
    };
    _ = SendInput(6, &inputs[0], @sizeOf(INPUT));
}

pub fn collapseSelection() void {
    var inputs: [2]INPUT = .{
        keyInput(VK_RIGHT, 0),
        keyInput(VK_RIGHT, KEYEVENTF_KEYUP),
    };
    _ = SendInput(2, &inputs[0], @sizeOf(INPUT));
}

pub fn moveHome() void {
    var inputs: [2]INPUT = .{
        keyInput(VK_HOME, 0),
        keyInput(VK_HOME, KEYEVENTF_KEYUP),
    };
    _ = SendInput(2, &inputs[0], @sizeOf(INPUT));
}

pub fn deleteChars(n: usize) void {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var inputs: [2]INPUT = .{
            keyInput(VK_DELETE, 0),
            keyInput(VK_DELETE, KEYEVENTF_KEYUP),
        };
        _ = SendInput(2, &inputs[0], @sizeOf(INPUT));
    }
}

pub fn typeUnicodeText(text: []const u8, allocator: std.mem.Allocator) void {
    const units = std.unicode.utf8ToUtf16LeAlloc(allocator, text) catch return;
    defer allocator.free(units);
    for (units) |u| {
        var inputs: [2]INPUT = .{
            unicodeInput(u, 0),
            unicodeInput(u, KEYEVENTF_KEYUP),
        };
        _ = SendInput(2, &inputs[0], @sizeOf(INPUT));
    }
}
