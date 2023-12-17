const std = @import("std");
const fmt = std.fmt;
const log = std.log;
const mem = std.mem;
const proc = std.process;
const time = std.time;

const c = @cImport({
    @cInclude("ncurses.h");
});

pub fn main() !void {
    defer {
        log.info("Thanks for playing!", .{});
        time.sleep(1 * time.ns_per_s);
        std.os.exit(0);
    }

    // Main Screen
    _ = c.initscr();
    defer _ = c.endwin();
    _ = c.noecho();
    _ = c.curs_set(c.FALSE);

    var max_x: c_int = c.getmaxx(c.stdscr);
    var max_y: c_int = c.getmaxy(c.stdscr);

    // Input
    _ = c.nodelay(c.stdscr, true);
    _ = c.keypad(c.stdscr, true);

    // Game Window
    const game_win = c.newwin(max_y - @divTrunc(max_y, @as(c_int, 4)), max_x, 0, 0);
    var game_max_x: c_int = c.getmaxx(game_win) - 1;
    var game_max_y: c_int = c.getmaxy(game_win) - 1;

    // Score Window
    const score_win = c.newwin(max_y - @divTrunc(max_y, @as(c_int, 4)) * 3, max_x, game_max_y, 0);

    // Ball
    const ball_txt = 
        \\+---+
        \\|   |
        \\+---+
    ;
    //const ball_txt = "oo\noo";
    const ball_w = getWidth(ball_txt);
    const ball_h = getHeight(ball_txt);
    const ball_win = c.newwin(ball_h, ball_w, 1, 1);
    var ball_fmt: [100]u8 = .{ 0 } ** 100;
    _ = mem.replace(u8, ball_txt[0..], "\n", "", ball_fmt[0..]);
    _ = c.mvwprintw(ball_win, 0, 0, ball_fmt[0..].ptr);

    var ball_x: c_int = @divTrunc(game_max_x, 2);
    var ball_y: c_int = @divTrunc(game_max_y, 2);
    var ball_x_dir: i8 = 1;
    var ball_y_dir: i8 = 1;

    // Players
    const ply_txt = 
        \\[]
        \\[]
        \\[]
    ;
    const ply_w = getWidth(ply_txt);
    const ply_h = getHeight(ply_txt);

    var ply_fmt: [100]u8 = .{ 0 } ** 100;
    _ = mem.replace(u8, ply_txt[0..], "\n", "", ply_fmt[0..]);

    const p1_win = c.newwin(ply_h, ply_w, @divTrunc(game_max_y, 2), 5); 
    _ = c.mvwprintw(p1_win, 0, 0, ply_fmt[0..].ptr);
    var p1_x: c_int = 5;
    var p1_y: c_int = @divTrunc(game_max_y, 2);

    const p2_win = c.newwin(ply_h, ply_w, @divTrunc(game_max_y, 2), max_x - 5); 
    _ = c.mvwprintw(p2_win, 0, 0, ply_fmt[0..].ptr);
    var p2_x: c_int = max_x - 5;
    var p2_y: c_int = @divTrunc(game_max_y, 2);

    var done: bool = false;
    var input_thread = try std.Thread.spawn(.{}, getInput, .{
        &p1_x, &p1_y,
        &p2_x, &p2_y,
        &ply_w, &ply_h,
        &game_max_x, &game_max_y,
        &done,
    });

    // Score
    var score_p1: u8 = 0;
    var score_p2: u8 = 0;


    while (true) : ({
        max_x = c.getmaxx(c.stdscr);
        max_y = c.getmaxy(c.stdscr);
        game_max_x = c.getmaxx(game_win) - 1;
        game_max_y = c.getmaxy(game_win) - 1;
        _ = c.wresize(game_win, max_y - @divTrunc(max_y, @as(c_int, 4)), max_x);
        _ = c.wclear(game_win);
        _ = c.wresize(score_win, max_y - @divTrunc(max_y, @as(c_int, 4)) * 3, max_x);
        _ = c.mvwin(score_win, game_max_y, 0);
        _ = c.wclear(score_win);
        time.sleep(100 * time.ns_per_ms);
    }) {
        // Board
        drawBorder(game_win);
        _ = c.wrefresh(game_win);

        // Score
        drawBorder(score_win);
        const score_y = 4;
        const score_x = @divTrunc(max_x, @as(c_int, 4));
        var score_buf: [15]u8 = .{ 0 } ** 15;
        _ = c.mvwprintw(score_win, score_y, score_x - 8, (try fmt.bufPrint(score_buf[0..], "P1 Score: {d:0>3}", .{ score_p1 })).ptr);
        _ = c.mvwprintw(score_win, score_y, score_x * 3 - 8, (try fmt.bufPrint(score_buf[0..], "P2 Score: {d:0>3}", .{ score_p2 })).ptr);
        _ = c.mvwprintw(score_win, c.getmaxy(score_win) - @as(c_int, 2), @divTrunc(max_x, @as(c_int, 10)) * 4, "W/S: P1 | UP/DOWN: P2 | ENTER: Close"); 
        _ = c.wrefresh(score_win);

        // Ball
        _ = c.mvwin(ball_win, ball_y, ball_x);
        _ = c.wrefresh(ball_win);
        ball_x += ball_x_dir;
        ball_y += ball_y_dir;
        // - Player Collision
        if (
            ball_x <= p1_x + ply_w and
            (
                (ball_y >= p1_y and ball_y <= p1_y + ply_h) or
                (ball_y + ball_h >= p1_y and ball_y + ball_h <= p1_y + ply_h)
            ) 
        ) {
            ball_x_dir *= -1;
        }
        if (
            ball_x + ball_w >= p2_x and
            (
                (ball_y >= p2_y and ball_y <= p2_y + ply_h) or
                (ball_y + ball_h >= p2_y and ball_y + ball_h <= p2_y + ply_h)
            ) 
        ) {
            ball_x_dir *= -1;
        }
        // - Wall Collision
        if (ball_x <= 1) {
            ball_x_dir *= -1;
            score_p2 +%= 1;   
        }
        if (ball_x + ball_w >= game_max_x) {
            ball_x_dir *= -1;
            score_p1 +%= 1;   
        }
        if (ball_y <= 1 or ball_y + ball_h >= game_max_y) ball_y_dir *= -1;

        // Players
        _ = c.mvwin(p1_win, p1_y, p1_x);
        _ = c.wrefresh(p1_win);
        _ = c.mvwin(p2_win, p2_y, p2_x);
        _ = c.wrefresh(p2_win);

        // Input
        //p1_x = 5;
        //p2_x = game_max_x - (ply_w + @as(c_int, 5));
        switch (c.getch()) {
            c.KEY_ENTER, '\n' => break,
            //'w' => {
            //    if (p1_y > 1) p1_y -= 1;
            //},
            //'s' => {
            //    if (p1_y + ply_h < game_max_y) p1_y += 1;
            //},
            //c.KEY_UP => {
            //    if (p2_y > 1) p2_y -= 1;
            //},
            //c.KEY_DOWN => {
            //    if (p2_y + ply_h < game_max_y) p2_y += 1;
            //},
            else => {},
        }

        _ = c.refresh();
    }
    done = true;
    input_thread.join();

}

/// Get the first line break or null character in the provided String (`str`).
pub fn getWidth(str: []const u8) c_int {
    return @as(c_int, @intCast((mem.indexOfAny(u8, str, &.{ '\n', 0 }) orelse 2)));
}

/// Get the number of lines in the provided String (`str`).
pub fn getHeight(str: []const u8) c_int {
    var h: c_int = 1;
    for (str) |char| { if (char == '\n') h += 1; }
    return h;
}

/// Draw a border around the given Window (`win`).
pub fn drawBorder(win: *c.WINDOW) void {
    const max_x: c_int = c.getmaxx(win) - 1;
    const max_y: c_int = c.getmaxy(win) - 1;
    var x: c_int = 0;
    while (x < max_x) : (x += 1) {
        _ = c.mvwprintw(win, 0, x, "-");
        _ = c.mvwprintw(win, max_y, x, "-");
    }
    var y: c_int = 0;
    while (y < max_y) : (y += 1) {
        _ = c.mvwprintw(win, y, 0, "|");
        _ = c.mvwprintw(win, y, max_x, "|");
    }
    _ = c.mvwprintw(win, 0, 0, "+");
    _ = c.mvwprintw(win, 0, max_x, "+");
    _ = c.mvwprintw(win, max_y, 0, "+");
    _ = c.mvwprintw(win, max_y, max_x, "+");
}

/// Get Input
pub fn getInput(
    p1_x: *c_int, p1_y: *c_int, 
    p2_x: *c_int, p2_y: *c_int, 
    ply_h: *const c_int, ply_w: *const c_int, 
    game_max_x: *c_int, game_max_y: *c_int,
    done: *bool,
) void {
    while (!done.*) {
        p1_x.* = 5;
        p2_x.* = game_max_x.* - (ply_w.* + @as(c_int, 5));
        switch (c.getch()) {
            //c.KEY_ENTER, '\n' => break,
            'w' => {
                if (p1_y.* > 1) p1_y.* -= 1;
            },
            's' => {
                if (p1_y.* + ply_h.* < game_max_y.*) p1_y.* += 1;
            },
            c.KEY_UP => {
                if (p2_y.* > 1) p2_y.* -= 1;
            },
            c.KEY_DOWN => {
                if (p2_y.* + ply_h.* < game_max_y.*) p2_y.* += 1;
            },
            else => {},
        }
    }
}
