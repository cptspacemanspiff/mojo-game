from ncurses import ffi


@fieldwise_init
struct Rect(ImplicitlyCopyable, Writable):
    var row: Int
    var col: Int
    var width: Int
    var height: Int

    def write_repr_to(self, mut writer: Some[Writer]):
        writer.write(
            t"Rect(row:{self.row}, coliumn:{self.col},"
            t" width:{self.width},"
            t" height:{self.height})"
        )

    def center_col(self) -> Int:
        return self.col + (self.width // 2)

    def center_row(self) -> Int:
        return self.row + (self.height // 2)


struct Window(Movable):
    var _win: ffi.NCurseWindow
    var _win_shape: Rect

    def __init__(out self):
        self._win = ffi.initscr()
        comptime locale = ""
        try:
            _ = ffi.setlocale(ffi.FLAG_LOCALE.ALL, locale.as_c_string_slice())
            ffi.cbreak()
            ffi.noecho()
        except e:
            print("Failed to init: " + e._error)

        self._win_shape = Rect(
            0,
            0,
            ffi.getmaxx(self._win),
            ffi.getmaxy(self._win),
        )

    def update_window_shape(mut self) -> Rect:
        self._win_shape = Rect(
            0, 0, ffi.getmaxx(self._win), ffi.getmaxy(self._win)
        )
        return self._win_shape

    def get_window_shape(self) -> Rect:
        return self._win_shape

    def __del__(deinit self):
        try:
            ffi.endwin()
        except e:
            print("Failed to de-init: " + e._error)

    # Forces a refresh of the display buffer
    def wait_for_input(self) -> Int:
        var originalDelay = ffi.wgetdelay(self._win)
        ffi.wtimeout(self._win, -1)  # wait forevever
        var val = ffi.wgetch(self._win)
        ffi.wtimeout(self._win, originalDelay)
        return val

    def clear(self) :
        try:
            ffi.wclear(self._win)
        except e:
            print(e)

    def write_string(self, text: String):
        try:
            ffi.waddnwstr(self._win, text)
        except e:
            print(e)

    def move_cursor(self, row: Int, col: Int) -> None:
        try:
            ffi.wmove(self._win, row, col)
        except e:
            print(e)

    def write_char(self, row: Int, col: Int, glyph: Codepoint) raises -> None:
        ffi.wmove(self._win, row, col)
        ffi.waddnwstr(self._win, String(glyph))

    def write_hline(
        mut self, row_start: Int, col_start: Int, length: Int, glyph: Codepoint
    ) raises -> None:
        for col in range(col_start, col_start + length):
            self.write_char(row_start, col, glyph)
            pass

    def write_vline(
        mut self, row_start: Int, col_start: Int, length: Int, glyph: Codepoint
    ) raises -> None:
        for row in range(row_start, row_start + length):
            self.write_char(row, col_start, glyph)
            pass

    def draw_rect_border(mut self, rect: Rect):
        try:
            # print(rect)
            self.write_vline(
                rect.row, rect.col, rect.height - 1, Codepoint.ord("│")
            )  # V Left bar
            self.write_vline(
                rect.row,
                rect.col + rect.width - 1,
                rect.height - 1,
                Codepoint.ord("│"),
            )  # V Right

            self.write_hline(
                rect.row, rect.col, rect.width - 1, Codepoint.ord("─")
            )  # Htop
            self.write_hline(
                rect.row + rect.height - 1,
                rect.col,
                rect.width - 1,
                Codepoint.ord("─"),
            )  # Hbottom

            # go over this and do the proper corner glyphs
            self.write_char(rect.row, rect.col, Codepoint.ord("┌"))
            self.write_char(
                rect.row, rect.col + rect.width - 1, Codepoint.ord("┐")
            )
            self.write_char(
                rect.row + rect.height - 1, rect.col, Codepoint.ord("└")
            )
            self.write_char(
                rect.row + rect.height - 1,
                rect.col + rect.width - 1,
                Codepoint.ord("┘"),
            )

        except e:
            print(e)
