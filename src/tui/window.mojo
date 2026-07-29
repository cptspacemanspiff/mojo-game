from ncurses import ffi


@fieldwise_init
struct Rect(ImplicitlyCopyable, Writable):
    var row: Int
    var column: Int
    var width: Int
    var height: Int

    def write_repr_to(self, mut writer: Some[Writer]):
        writer.write(
            t"Rect(row:{self.row}, coliumn:{self.column},"
            t" width:{self.width},"
            t" height:{self.height})"
        )


struct Window(Movable):
    var _win: ffi.NCurseWindow
    var _win_shape: Rect

    def __init__(out self):
        self._win = ffi.initscr()

        try:
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
    def wait_for_input(self):
        var originalDelay = ffi.wgetdelay(self._win)
        ffi.wtimeout(self._win, -1)  # wait forevever
        _ = ffi.wgetch(self._win)
        ffi.wtimeout(self._win, originalDelay)

    def write_string(self, text: String):
        try:
            var mut_text = String(text)
            ffi.waddnstr(self._win, mut_text.as_c_string_slice())
        except e:
            print(e)

    def draw_rect_border(self, rect: Rect):
        try:
            ffi.whline(
                self._win, rect.row, rect.column, rect.width, UInt(ord("-"))
            )  # Htop

            ffi.whline(
                self._win,
                rect.row + rect.height - 1,
                rect.column,
                rect.width,
                UInt(ord("-")),
            )  # H bottom

            ffi.wvline(
                self._win, rect.row, rect.column, rect.height, UInt(ord("|"))
            )  # V Left bar

            ffi.wvline(
                self._win,
                rect.row,
                rect.column + rect.width - 1,
                rect.height,
                UInt(ord("|")),
            )  # V Right
        except e:
            print(e)
