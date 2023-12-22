const std = @import("std");
const fmt = std.fmt;
const log = std.log;
const mem = std.mem;
const proc = std.process;
const time = std.time;

const c = @cImport({
    @cInclude("ncurses.h");
});


const Tab = struct{
    title: []const u8,
    content: []const u8,
};

const tabs = [_]Tab{
    .{ .title = "First", .content = "This is the First tab!" },
    .{ .title = "Second", .content = "This is the Second tab!" },
    .{ .title = "Third", .content = "This is the Third tab!" },
};

pub fn main() !void {
    defer std.os.exit(0);
    _ = c.initscr();
    _ = c.cbreak();
    _ = c.noecho();
    _ = c.keypad(c.stdscr, true);

    var cur_tab: usize = 0;

    while (true) {
        _ = c.clear();
        try displayTabs(cur_tab);
        try displayContents(cur_tab);
        _ = c.refresh();

        switch (c.getch()) {
            c.KEY_LEFT => cur_tab -|= 1,
            c.KEY_RIGHT => cur_tab = @min(cur_tab + 1, tabs.len - 1),
            'q' => {
                _ = c.endwin();
                break; 
            },
            else => {},
        }
    }
}

fn displayTabs(tab_idx: usize) !void {
    for (tabs, 0..) |tab, idx| {
        if (idx == tab_idx) _ = c.attron(c.A_REVERSE);
        var title_buf: [20]u8 = .{ 0 } ** 20;
        const title = try fmt.bufPrint(title_buf[0..], "{s}\t", .{ tab.title });
        _ = c.printw(title[0..].ptr);
        _ = c.attroff(c.A_REVERSE);
    }
}

fn displayContents(tab_idx: usize) !void {
    var contents_buf: [100]u8 = .{ 0 } ** 100;
    const contents = try fmt.bufPrint(
        contents_buf[0..], 
        \\
        \\------------------------
        \\
        \\{s}
        \\
        , .{ tabs[tab_idx].content }
    );
    _ = c.printw(contents[0..].ptr);
}
