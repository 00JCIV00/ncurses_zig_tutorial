const std = @import("std");
const fmt = std.fmt;
const log = std.log;
const time = std.time;

const c = @cImport({
    @cInclude("ncurses.h");
});

pub fn main() !void {
    defer std.os.exit(0);

    // Main Screen
    _ = c.initscr();
    defer _ = c.endwin();
    _ = c.noecho();
    _ = c.curs_set(c.FALSE);

    var max_x: i32 = c.getmaxx(c.stdscr);
    var max_y: i32 = c.getmaxy(c.stdscr);

    // Game Window
    const game_win = c.newwin(max_y - @divTrunc(max_y, @as(i32, 4)), max_x, 0, 0);
    var game_max_x: i32 = c.getmaxx(game_win) - 1;
    var game_max_y: i32 = c.getmaxy(game_win) - 1;

    // Score Window
    const score_win = c.newwin(max_y - @divTrunc(max_y, @as(i32, 4)) * 3, max_x, game_max_y, 0);

    // Ball
    var ball_x: i32 = 0;
    var ball_y: i32 = 0;
    //const ball_txt = 
    //    \\+---+
    //    \\|   |
    //    \\+---+
    //;
    const ball_txt = "o";

    var ball_x_dir: i8 = 2;
    var ball_y_dir: i8 = 2;

    // Score
    var score_p1: u8 = 0;
    var score_p2: u8 = 0;


    while (true) : ({
        max_x = c.getmaxx(c.stdscr);
        max_y = c.getmaxy(c.stdscr);
        game_max_x = c.getmaxx(game_win) - 1;
        game_max_y = c.getmaxy(game_win) - 1;
        _ = c.wresize(game_win, max_y - @divTrunc(max_y, @as(i32, 4)), max_x);
        _ = c.wclear(game_win);
        _ = c.wresize(score_win, max_y - @divTrunc(max_y, @as(i32, 4)) * 3, max_x);
        _ = c.mvwin(score_win, game_max_y, 0);
        _ = c.wclear(score_win);
        time.sleep(100 * time.ns_per_ms);
    }) {
        drawBorder(game_win);
        _ = c.mvwprintw(game_win, ball_y, ball_x, ball_txt);
        _ = c.wrefresh(game_win);
        ball_x += ball_x_dir;
        ball_y += ball_y_dir;
        if (ball_x <= 1) {
            ball_x_dir *= -1;
            score_p2 +%= 1;   
        }
        if (ball_x + @as(i32, @intCast(ball_txt.len)) >= game_max_x) {
            ball_x_dir *= -1;
            score_p1 +%= 1;   
        }
        if (ball_y <= 1 or ball_y + getHeight(ball_txt) >= game_max_y) ball_y_dir *= -1;

        drawBorder(score_win);
        const score_y = 2;
        const score_x = @divTrunc(max_x, @as(i32, 4));
        var score_buf: [15]u8 = .{ 0 } ** 15;
        _ = c.mvwprintw(score_win, score_y, score_x - 8, (try fmt.bufPrint(score_buf[0..], "P1 Score: {d:0>3}", .{ score_p1 })).ptr);
        _ = c.mvwprintw(score_win, score_y, score_x * 3 - 8, (try fmt.bufPrint(score_buf[0..], "P2 Score: {d:0>3}", .{ score_p2 })).ptr);
        _ = c.wrefresh(score_win);

        _ = c.refresh();
    }

    time.sleep(1 * time.ns_per_s);
}

/// Get the number of lines in the provided String (`str`).
pub fn getHeight(str: []const u8) i32 {
    var h: i32 = 1;
    for (str) |char| { if (char == '\n') h += 1; }
    return h;
}

/// Draw a border around the given Window (`win`).
pub fn drawBorder(win: *c.WINDOW) void {
    const max_x: i32 = c.getmaxx(win) - 1;
    const max_y: i32 = c.getmaxy(win) - 1;
    var x: i32 = 0;
    while (x < max_x) : (x += 1) {
        _ = c.mvwprintw(win, 0, x, "-");
        _ = c.mvwprintw(win, max_y, x, "-");
    }
    var y: i32 = 0;
    while (y < max_y) : (y += 1) {
        _ = c.mvwprintw(win, y, 0, "|");
        _ = c.mvwprintw(win, y, max_x, "|");
    }
    _ = c.mvwprintw(win, 0, 0, "+");
    _ = c.mvwprintw(win, 0, max_x, "+");
    _ = c.mvwprintw(win, max_y, 0, "+");
    _ = c.mvwprintw(win, max_y, max_x, "+");
}
