const std = @import("std");

pub const TranslateService = enum {
    google,
    bing,
};

pub fn translateText(text: []const u8, service: TranslateService, allocator: std.mem.Allocator) !?[]u8 {
    _ = service;
    _ = allocator;
    
    // پیاده‌سازی ساده - در نسخه کامل باید HTTP request بزنیم
    // برای Google Translate: https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=fa&dt=t&q=TEXT
    
    return null;
}

pub fn getGoogleTranslateUrl(text: []const u8) []const u8 {
    _ = text;
    return "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=fa&dt=t&q=";
}
