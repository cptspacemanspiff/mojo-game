# define KEY_DOWN	0402		/* down-arrow key */
# define KEY_UP		0403		/* up-arrow key */
# define KEY_LEFT	0404		/* left-arrow key */
# define KEY_RIGHT	0405		/* right-arrow key */

# define KEY_ENTER	0527		/* enter/send key */

# define KEY_RESIZE	0632		/* Terminal resize event */


struct InputEvent(Equatable, ImplicitlyCopyable):
    var _value: Int

    # ncurses spells these as octal literals; keep the 0o prefix so the
    # values stay readable against curses.h.
    # comptime KEY_DOWN = InputEvent(0o402)
    # comptime KEY_UP = InputEvent(0o403)
    # comptime KEY_LEFT = InputEvent(0o404)
    # comptime KEY_RIGHT = InputEvent(0o405)

    # wasd:

    comptime KEY_DOWN = InputEvent(ord("s"))
    comptime KEY_UP = InputEvent(ord("w"))
    comptime KEY_LEFT = InputEvent(ord("a"))
    comptime KEY_RIGHT = InputEvent(ord("d"))

    comptime KEY_SPACE = InputEvent(ord(" "))
    comptime KEY_RESIZE = InputEvent(0o632)

    comptime KEY_Q_UPPER = InputEvent(ord("Q"))
    comptime KEY_Q_LOWER = InputEvent(ord("q"))

    def __int__(self) -> Int:
        return Int(self._value)

    def __init__(out self, value: Int):
        self._value = value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __ne__(self, other: Self) -> Bool:
        return not (self == other)
