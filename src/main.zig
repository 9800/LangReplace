pub fn main() !void {
    const hModule: ?HMODULE = windows.kernel32.GetModuleHandleW(null);
    
    // ✅ رفع خطا: cast صحیح optional pointer
    g_hInstance = @ptrCast(hModule);

    const className = "LangReplaceWindow";
    
    const wc: WNDCLASSEXW = .{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = 0,
        .lpfnWndProc = windowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = g_hInstance,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = className,
        .hIconSm = null,
    };

    _ = RegisterClassExW(&wc);

    const hWnd = CreateWindowExW(
        0,
        className,
        "LangReplace",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        null,
        null,
        g_hInstance,
        null,
    ) orelse return error.WindowCreationFailed;

    g_tray = try tray.TrayManager.init(hWnd);
    _ = hotkey.registerHotkeys(hWnd);

    _ = ShowWindow(hWnd, SW_HIDE);

    var msg: windows.MSG = undefined;
    while (GetMessageW(&msg, null, 0, 0) != 0) {
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
}
