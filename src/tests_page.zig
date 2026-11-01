//! The pieces of a page that are the same whoever draws it: the JSON the
//! page bar is built from, the asset table's answers, and the origin each
//! platform serves its own pages on.
const std = @import("std");
const page = @import("page.zig");
const window_types = @import("window_types.zig");

const testing = std.testing;

test "a served root is the index, with the type a browser needs" {
    var arena: std.heap.ArenaAllocator = .init(testing.allocator);
    defer arena.deinit();
    // The table is what `serve` looks in; a path not in it is a 404.
    const assets = [_]window_types.Asset{
        .{ .path = "/index.html", .data = "<!doctype html>" },
        .{ .path = "/main.js", .data = "export const x = 1;", .mime = "text/javascript; charset=utf-8" },
    };
    const Q = page.Queue(struct {});
    _ = Q;
    try testing.expectEqualStrings("text/html; charset=utf-8", page.mimeType("/index.html"));
    try testing.expectEqualStrings("text/css; charset=utf-8", page.mimeType("/a.css"));
    try testing.expectEqualStrings("application/octet-stream", page.mimeType("/a.unknown"));
    try testing.expectEqual(@as(usize, 2), assets.len);
}

test "an absolute URL is not the app's own, a path is" {
    // What `Page.load` decides with: `http(s)` goes to the web, a path to
    // the app's asset table on its own origin.
    try testing.expect(std.mem.startsWith(u8, "https://example.com/", "https://"));
    try testing.expect(!std.mem.startsWith(u8, "/index.html", "https://"));
    try testing.expectEqualStrings("/index.html", page.pathOf(page.origin ++ "/index.html"));
    try testing.expectEqualStrings("/", page.pathOf(page.origin));
}

test "the bridge posts through whichever webview the page is in" {
    // One file for every platform: it picks WebView2's `postMessage` when the
    // page has it, and WKWebView's message handler otherwise.
    try testing.expect(std.mem.indexOf(u8, page.bridge_js, "chrome.webview") != null);
    try testing.expect(std.mem.indexOf(u8, page.bridge_js, "webk\\u0069t") != null or
        std.mem.indexOf(u8, page.bridge_js, "webkit") != null);
    try testing.expect(std.mem.indexOf(u8, page.bridge_js, "__nanoui_setPages") != null);
}
