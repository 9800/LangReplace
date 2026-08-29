const std = @import("std");

pub const Config = struct {
    ignore_upper_case: bool = true,
    ignore_english: bool = true,
    enable_middle_mouse: bool = false,
    hotkey_convert: u32 = 0x79, // F10
    hotkey_reverse: u32 = 0x75, // F6
    hotkey_case: u32 = 0x79, // F10 with Shift

    pub fn load(allocator: std.mem.Allocator) !Config {
        const config_path = getConfigPath();
        const file = std.fs.cwd().openFile(config_path, .{}) catch {
            return Config{};
        };
        defer file.close();

        const content = file.readToEndAlloc(allocator, 1024) catch {
            return Config{};
        };
        defer allocator.free(content);

        // پارس کردن JSON ساده
        var config = Config{};
        // در نسخه کامل از std.json استفاده می‌کنیم
        
        return config;
    }

    pub fn save(self: Config, allocator: std.mem.Allocator) !void {
        const config_path = getConfigPath();
        const file = std.fs.cwd().createFile(config_path, .{}) catch return;
        defer file.close();

        // نوشتن JSON ساده
        const json = std.fmt.allocPrint(allocator, "{{\"ignore_upper_case\":{s},\"ignore_english\":{s}}}", .{
            if (self.ignore_upper_case) "true" else "false",
            if (self.ignore_english) "true" else "false",
        }) catch return;
        defer allocator.free(json);

        _ = file.write(json);
    }

    fn getConfigPath() []const u8 {
        return "langreplace_config.json";
    }
};
