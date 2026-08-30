const config = @import("config.zig");

pub fn isFa() bool {
    return config.g_config.language == 1;
}

pub fn t(en: []const u8, fa: []const u8) []const u8 {
    return if (isFa()) fa else en;
}
