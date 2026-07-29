# from .helpers
from std.ffi import CStringSlice, OwnedDLHandle
from std.ffi import c_int, c_uint, external_call

from std.memory import MutOpaquePointer
from std.sys.terminate import exit


## LOCALE FLAGS
# define __LC_CTYPE		 0
# define __LC_NUMERIC		 1
# define __LC_TIME		 2
# define __LC_COLLATE		 3
# define __LC_MONETARY		 4
# define __LC_MESSAGES		 5
# define __LC_ALL		 6
# define __LC_PAPER		 7
# define __LC_NAME		 8
# define __LC_ADDRESS		 9
# define __LC_TELEPHONE		10
# define __LC_MEASUREMENT	11
# define __LC_IDENTIFICATION	12


@fieldwise_init
struct FLAG_LOCALE(Equatable, ImplicitlyCopyable):
    var _value: Int

    comptime ALL = FLAG_LOCALE(6)

    def __int__(self) -> c_int:
        return c_int(self._value)

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __ne__(self, other: Self) -> Bool:
        return not (self == other)


# Set Locale allows us to set the unicode for the
def setlocale(category: FLAG_LOCALE, locale: CStringSlice) raises -> String:
    var ret = external_call[
        "setlocale", Optional[CStringSlice[ImmutUntrackedOrigin]]
    ](category, locale)
    if ret is None:
        raise Error("setlocale returned NULL")

    return String(ret[])


@fieldwise_init
struct NCurseWindow(ImplicitlyCopyable, Movable):
    var _ptr: MutOpaquePointer[MutUntrackedOrigin]

    # def __init__(out self, ptr: MutOpaquePointer[MutUntrackedOrigin]):
    #     self._windowPtr = ptr


comptime RAW_WINDOW = MutOpaquePointer[MutUntrackedOrigin]


# Init screen creates a new screen session and sets it to the current one is a global held in ncurses.
def initscr() -> NCurseWindow:
    var ret = external_call["initscr", Optional[RAW_WINDOW]]()

    # ncurses should kill the process and not return NULL
    if ret is None:
        print(
            "NCurse window returned null for initscr - supposedly impossible..."
        )
        exit(1)

    # we manually checked to that it is unsafe
    var win = NCurseWindow(ret.unsafe_take())
    return win^


struct _Result(Boolable):
    var _Succeded: Bool

    def __init__(out self, c_returned: c_int):
        if c_returned == 0:
            self._Succeded = True
        else:
            self._Succeded = False

    def __bool__(self) -> Bool:
        return self._Succeded


# end win, closes the current screen.
def endwin() raises -> None:
    if not _Result(external_call["endwin", c_int]()):
        raise Error("ncurses endwin() failed")


# Make keyboard inputs availiable once character at a time w/o waiting for enter.
def cbreak() raises -> None:
    if not _Result(external_call["cbreak", c_int]()):
        raise Error("ncurses cbreak() failed")


# Do not print the terminal values:
def noecho() raises -> None:
    if not _Result(external_call["noecho", c_int]()):
        raise Error("ncurses noecho() failed")


@fieldwise_init
struct FLAG_VISIBLE(Equatable, ImplicitlyCopyable):
    var _value: Int

    comptime HIDDEN = FLAG_VISIBLE(0)
    comptime VISIBLE = FLAG_VISIBLE(1)
    comptime VERY_VISIBLE = FLAG_VISIBLE(2)

    def __int__(self) -> Int:
        return self._value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __ne__(self, other: Self) -> Bool:
        return not (self == other)


def curs_set(vis: FLAG_VISIBLE) raises -> None:
    if _Result(external_call["curs_set", c_int](vis)):
        raise Error("ncurses curs_set() failed")


# input timeout:
# timeout < 0, wait forever
# timeout = 0, non-blocking
# timeout > 0, wait that many ms
def wtimeout(win: NCurseWindow, timeout_ms: Int) -> None:
    external_call["curs_set", NoneType](win._ptr, c_int(timeout_ms))


def wgetdelay(win: NCurseWindow) -> Int:
    return Int(external_call["wgetdelay", c_int](win._ptr))


def keypad(win: NCurseWindow, enable: Bool) raises -> None:
    if not _Result(external_call["noecho", c_int](win._ptr, enable)):
        raise Error("ncurses keypad() failed")


def waddnstr(win: NCurseWindow, text: CStringSlice) raises -> None:
    var length: Int = len(text)
    if not _Result(
        external_call["waddnstr", c_int](win._ptr, text, c_int(length))
    ):
        raise Error("ncurses waddnstr() failed")


def wrefresh(win: NCurseWindow) raises -> None:
    if not _Result(external_call["wrefresh", c_int](win._ptr)):
        raise Error("ncurses waddnstr() failed")


def wgetch(win: NCurseWindow) -> Int:
    return Int(external_call["wgetch", c_int](win._ptr))


## WINDOW DIMS:


def getmaxx(win: NCurseWindow) -> Int:
    return Int(external_call["getmaxx", c_int](win._ptr))


def getmaxy(win: NCurseWindow) -> Int:
    return Int(external_call["getmaxy", c_int](win._ptr))


def wmove(win: NCurseWindow, row: Int, column: Int) raises -> None:
    if not _Result(
        external_call["wmove", c_int](win._ptr, c_int(row), c_int(column))
    ):
        raise Error("ncurses wmove() failed")


def whline(
    win: NCurseWindow, row: Int, column: Int, length: Int, character: UInt
) raises -> None:
    wmove(win, row, column)
    if not _Result(
        external_call["whline", c_int](
            win._ptr, c_uint(character), c_int(length)
        )
    ):
        raise Error("ncurses whline() failed")


def wvline(
    win: NCurseWindow, row: Int, column: Int, length: Int, character: UInt
) raises -> None:
    wmove(win, row, column)
    if not _Result(
        external_call["wvline", c_int](
            win._ptr, c_uint(character), c_int(length)
        )
    ):
        raise Error("ncurses wvline() failed")


def mvwaddch(
    win: NCurseWindow, row: Int, column: Int, character: UInt
) raises -> None:
    wmove(win, row, column)
    if not _Result(
        external_call["mvwaddch", c_int](win._ptr, c_uint(character))
    ):
        raise Error("ncurses mvwaddch() failed")
