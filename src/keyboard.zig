const std = @import("std");
const windows = std.os.windows;

const UINT = windows.UINT;
const DWORD = windows.DWORD;

const INPUT_KEYBOARD: DWORD = 1;
const KEYEVENTF_KEYUP: DWORD = 0x0002;
const VK_CONTROL: u16 = 0x11;

pub const VK_C: u16 = 0x43;
pub const VK_V: u16 = 0x56;

const MOUSEINPUT = extern struct {
    dx: i32,
    dy: i32,
    mouseData: DWORD,
    dwFlags: DWORD,
    time: DWORD,
    dwExtraInfo: usize,
};

const KEYBDINPUT = extern struct {
    wVk: u16,
    wScan: u16,
    dwFlags: DWORD,
    time: DWORD,
    dwExtraInfo: usize,
};

const HARDWAREINPUT = extern struct {
    uMsg: DWORD,
    wParamL: u16,
    wParamH: u16,
};

const INPUT_U = extern union {
    mi: MOUSEINPUT,
    ki: KEYBDINPUT,
    hi: HARDWAREINPUT,
};

const INPUT = extern struct {
    type: DWORD,
    u: INPUT_U,
};

extern "user32" fn SendInput(cInputs: UINT, pInputs: *INPUT, cbSize: i32) callconv(windows.WINAPI) UINT;

fn keyInput(vk: u16, flags: DWORD) INPUT {
    return INPUT{
        .type = INPUT_KEYBOARD,
        .u = .{ .ki = .{
            .wVk = vk,
            .wScan = 0,
            .dwFlags = flags,
            .time = 0,
            .dwExtraInfo = 0,
        } },
    };
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
