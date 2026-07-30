from tui.window import Window, Rect
from tui.inputs import InputEvent

from std import random
from std.collections import List, Dict
from std.memory import ArcPointer


@fieldwise_init
struct Player(ImplicitlyCopyable, Movable):
    var glyph: Codepoint
    var id: Int  # do not use player 0 or they


@fieldwise_init
struct CellState(ImplicitlyCopyable, Movable):
    var _value: Int

    comptime Free = CellState(0)
    comptime Player1 = CellState(1)
    comptime Player2 = CellState(2)

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __ne__(self, other: Self) -> Bool:
        return not (self == other)

    def get_owned_by(self, player_id: Int) -> Bool:
        if self._value == player_id:
            return True
        return False


@fieldwise_init
struct Movement(ImplicitlyCopyable, Movable):
    var _value: Int

    comptime LEFT = Movement(0)
    comptime RIGHT = Movement(1)
    comptime UP = Movement(2)
    comptime DOWN = Movement(3)

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __ne__(self, other: Self) -> Bool:
        return not (self == other)


@fieldwise_init
struct Coordinate(Equatable, Hashable, ImplicitlyCopyable, Writable):
    var row: Int
    var col: Int

    def write_to(self, mut writer: Some[Writer]):
        writer.write(t"Coor(row:{self.row}, col:{self.col})")

    def write_repr_to(self, mut writer: Some[Writer]):
        writer.write(t"Coor(row:{self.row}, col:{self.col})")


struct GameState:
    # Row major:
    var game_board: List[List[CellState]]
    var current_player_idx: Int
    var cursor_cell: Coordinate

    var players: List[Player]

    def __init__(out self):
        self.game_board = [
            [CellState.Free, CellState.Free, CellState.Free],
            [CellState.Free, CellState.Free, CellState.Free],
            [CellState.Free, CellState.Free, CellState.Free],
        ]
        self.cursor_cell = Coordinate(1, 1)  # start at the center:
        self.current_player_idx = Int(random.random_si64(0, 1))
        self.players = [
            Player(Codepoint.ord("X"), 1),
            Player(Codepoint.ord("O"), 2),
        ]

    def get_cursor_cell(self) -> Coordinate:
        return self.cursor_cell

    def advance_turn(mut self):
        self.current_player_idx = (self.current_player_idx + 1) % 2

    def get_cell_codepoint(self, coordinate: Coordinate) -> Codepoint:
        var cell = self.game_board[coordinate.row][coordinate.col]
        if cell == CellState.Player1:
            return self.players[0].glyph
        elif cell == CellState.Player2:
            return self.players[1].glyph
        return Codepoint.ord(" ")  # blank on free:

    def play(mut self, cell_coor: Coordinate) raises:
        ref state = self.game_board[cell_coor.row][cell_coor.col]
        if state != CellState.Free:
            raise Error("Cell already owned by a player")
        if self.current_player_idx == 0:
            state = CellState.Player1
        elif self.current_player_idx == 1:
            state = CellState.Player2
        else:
            raise Error("Unknown Player")

    def check_win(self, player: Player) -> Bool:
        comptime board_dim = 3
        comptime max_index = board_dim - 1
        # Check rows for a winner:
        for row in range(board_dim):
            for col in range(board_dim):
                ref cell = self.game_board[row][col]
                if cell.get_owned_by(player.id) == False:
                    break
                if col == max_index:
                    return True

        # Check columns for a winner:
        for col in range(board_dim):
            for row in range(board_dim):
                ref cell = self.game_board[row][col]
                if cell.get_owned_by(player.id) == False:
                    break
                if row == max_index:
                    return True

        # Check down diagonal for a winner:
        for index in range(board_dim):
            ref cell = self.game_board[index][index]
            if cell.get_owned_by(player.id) == False:
                break
            if index == max_index:
                return True

        # diagonal up
        for index in range(board_dim):
            ref cell = self.game_board[max_index - index][max_index - index]
            if cell.get_owned_by(player.id) == False:
                break
            if index == max_index:
                return True

        return False

    def check_complete(self) -> Bool:
        for rows in self.game_board:
            for cell in rows:
                if cell == CellState.Free:
                    return False
        return True

    def reset(mut self) -> None:
        for ref rows in self.game_board:
            for ref cell in rows:
                cell = CellState.Free

    def update_cursor(mut self, move: Movement) -> None:
        def bounded_change(idx: Int, change: Int) -> Int:
            # inclusive bounds
            comptime max_idx = 2
            comptime min_idx = 0
            if idx + change >= max_idx:
                return max_idx
            elif idx + change <= min_idx:
                return min_idx
            else:
                return idx + change

        if move == Movement.LEFT:
            ref col_idx = self.cursor_cell.col
            col_idx = bounded_change(col_idx, -1)
        elif move == Movement.RIGHT:
            ref col_idx = self.cursor_cell.col
            col_idx = bounded_change(col_idx, 1)
        elif move == Movement.UP:
            ref row_idx = self.cursor_cell.row
            row_idx = bounded_change(row_idx, -1)
        elif move == Movement.DOWN:
            ref row_idx = self.cursor_cell.row
            row_idx = bounded_change(row_idx, 1)

        return None


struct TextBox(Movable):
    var p_win: ArcPointer[Window]
    # render text inside a rectangle -
    var text: List[String]
    var rev: Bool

    def __init__(
        out self, p_window: ArcPointer[Window], initial_text: List[String], rev : Bool
    ):
        self.p_win = p_window
        self.text = initial_text.copy()
        self.rev = rev

    def render_in_rect(self, rect: Rect, hmargin: Int = 0, wmargin: Int = 3):
        # We write text w/ each str on new line:
        var max_line_len = rect.width - 2 * wmargin
        var max_lines = rect.height - 2 * hmargin

        var row_start = rect.row + hmargin
        var col_start = rect.col + wmargin

        def write(i: Int, string : String){self, row_start, col_start, max_line_len,max_lines}:
            if i > max_lines - 2:
                return

            self.p_win[].move_cursor(row_start + i, col_start)
            self.p_win[].write_string(string, max_line_len)

        if self.rev:
            for i, string in enumerate(reversed(self.text)):
                write(i,string)
        else:
            for i, string in enumerate(self.text):
                write(i,string)

    def append_msg(mut self, msg: String) -> None:
        self.text.append(msg)


struct GameRenderer(Movable):
    var p_win: ArcPointer[Window]

    # map the game coordinates to render coordinates:
    var state_map: Dict[Coordinate, Coordinate]

    var window_rect: Rect

    var instruction_rect: Rect
    var log_rect: Rect

    def __init__(out self, p_window: ArcPointer[Window]):
        # Construct a window, to create a terminal to render in.
        self.p_win = p_window
        self.state_map = Dict[Coordinate, Coordinate]()
        self.window_rect = self.p_win[].update_window_shape()
        (self.instruction_rect, self.log_rect) = self.update_sub_rects(
            self.window_rect
        )

    def clear(mut self):
        self.p_win[].clear()

    def update_window_rect(mut self):
        self.window_rect = self.p_win[].update_window_shape()
        (self.instruction_rect, self.log_rect) = self.update_sub_rects(
            self.window_rect
        )

    @staticmethod
    def get_left_rect(input_rect: Rect) -> Rect:
        var w_l = input_rect.width // 2
        return Rect(input_rect.row, input_rect.col, w_l, input_rect.height)

    @staticmethod
    def get_right_rect(input_rect: Rect) -> Rect:
        var w_l = input_rect.width // 2
        return Rect(
            input_rect.row, input_rect.col + w_l + 1, w_l, input_rect.height
        )

    def get_instruction_rect(self) -> Rect:
        return self.instruction_rect

    def get_log_rect(self) -> Rect:
        return self.log_rect

    @staticmethod
    def update_sub_rects(window_rect: Rect) -> Tuple[Rect, Rect]:
        var right_rect_advancing = GameRenderer.get_right_rect(window_rect)
        var instruction_rect = GameRenderer.get_hsplit_rect(
            right_rect_advancing, 7, 1
        )
        var advance_incr = instruction_rect.height  # (1 margin)
        right_rect_advancing.row = right_rect_advancing.row + advance_incr
        right_rect_advancing.height = right_rect_advancing.height - advance_incr
        # Log rect is window rect height - instruction rect height -
        var log_rect = right_rect_advancing

        return (instruction_rect, log_rect)

    @staticmethod
    def get_hsplit_rect(input_rect: Rect, num_rows: Int, voffset: Int) -> Rect:
        return Rect(
            input_rect.row + voffset, input_rect.col, input_rect.width, num_rows
        )

    def draw_term_rect(mut self):
        self.p_win[].draw_rect_border(self.window_rect)
        self.p_win[].draw_rect_border(self.get_left_rect(self.window_rect))
        self.p_win[].draw_rect_border(self.get_right_rect(self.window_rect))

        # instruction_box:
        # self.p_win[].draw_rect_border(self.get_hsplit_rect(self.get_right_rect(self.window_rect),3,1))
        # self.p_win[].draw_rect_border(self.get_hsplit_rect(self.get_right_rect(self.window_rect),10,5))

    def draw_board_rect(mut self):
        # create a centered game board rectangle:
        var window_rect = self.get_left_rect(self.window_rect)

        comptime cell_height = 3
        comptime cell_width = cell_height * 3
        comptime board_height = cell_height * 3 + 4  # cells are 3x3, + 4 lines total 13
        comptime board_width = cell_width * 3 + 4
        ## place the board in the horizontal center,
        ## and 4 lines from the top of the screen.

        var game_board_outline = Rect(
            window_rect.center_row() - board_height // 2,
            window_rect.center_col() - board_width // 2,
            board_width,
            board_height,
        )
        self.p_win[].draw_rect_border(game_board_outline)

        try:
            # place horizontal lines on the board:
            for i in range(2):
                var row_offset = (cell_height + 1) * (i + 1)
                self.p_win[].write_hline(
                    game_board_outline.row + row_offset,
                    game_board_outline.col + 1,
                    board_width - 2,
                    Codepoint.ord("-"),
                )
            for i in range(2):
                var col_offset = (cell_width + 1) * (i + 1)
                self.p_win[].write_vline(
                    game_board_outline.row + 1,
                    game_board_outline.col + col_offset,
                    board_height - 2,
                    Codepoint.ord("|"),
                )

        except e:
            print(e)

        # Generate the Coordinate map:
        var row_start = (
            game_board_outline.row + (cell_height // 2) + 1
        )  # middle of cell (floor+1) + 1 line border
        var col_start = game_board_outline.col + (cell_width // 2) + 1
        for row_idx in range(3):
            var row_offset = (
                cell_height + 1
            ) * row_idx  # cell height+ 1 line border
            for col_idx in range(3):
                col_offset = (cell_width + 1) * col_idx
                # try:
                #     self.p_win[].write_char(row_start+row_offset,col_start+col_offset,Codepoint.ord('A'))
                # except:
                #     pass
                self.state_map[Coordinate(row_idx, col_idx)] = Coordinate(
                    row_start + row_offset, col_start + col_offset
                )
                # position is offset from the main

        # for item in self.state_map.items():
        #     print(repr(item.key), " -> ", repr(item.value))

    def place_cursor(self, cell_row: Int, cell_col: Int):
        try:
            var cursor_coor = self.state_map[Coordinate(cell_row, cell_col)]
            self.p_win[].move_cursor(cursor_coor.row, cursor_coor.col)
        except e:
            print(e)

        # self.p_win[].

    def draw_game_state(self, game_state: GameState):
        # write the cell states: X, O or empty
        for item in self.state_map.items():
            codepoint = game_state.get_cell_codepoint(item.key)
            try:
                self.p_win[].write_char(
                    item.value.row, item.value.col, codepoint
                )
            except e:
                print(e)

        # Update the cursor:
        self.place_cursor(
            game_state.cursor_cell.row, game_state.cursor_cell.col
        )


struct InputProcessor:
    var p_win: ArcPointer[Window]

    def __init__(out self, p_window: ArcPointer[Window]):
        # Construct a window, to create a terminal to render in.
        self.p_win = p_window

    def handle_input(self, input_event: InputEvent, mut game_state: GameState):
        # cursor movement:

        # uses WASD for movement
        if input_event == InputEvent.KEY_LEFT:
            game_state.update_cursor(Movement.LEFT)
        elif input_event == InputEvent.KEY_RIGHT:
            game_state.update_cursor(Movement.RIGHT)
        elif input_event == InputEvent.KEY_UP:
            game_state.update_cursor(Movement.UP)
        elif input_event == InputEvent.KEY_DOWN:
            game_state.update_cursor(Movement.DOWN)

        if input_event == InputEvent.KEY_SPACE:
            try:
                game_state.play(game_state.get_cursor_cell())
                game_state.advance_turn()
            except e:
                # print("Invalid")
                pass

        # Enter Handling:


def main() -> None:
    print("Tic-Tac-Toe 🌊")

    game_state = GameState()

    win_ptr = ArcPointer[Window](Window())
    renderer = GameRenderer(win_ptr)

    instructions = ArcPointer[TextBox](
        TextBox(
            win_ptr,
            [
                "Play Tic-Tac-Toe! 🌊",
                "Use w,a,s,d to move, and space to play.",
                "use q to quit",
                "---------",
                "Logs:",
            ],
            False,
        )
    )
    log = ArcPointer[TextBox](TextBox(win_ptr, ["Messages go here..."], True))

    renderer.draw_term_rect()
    renderer.draw_board_rect()

    # render instructions:
    instructions[].render_in_rect(renderer.get_instruction_rect())
    # render log:
    log[].render_in_rect(renderer.get_log_rect())

    input_processor = InputProcessor(win_ptr)

    renderer.draw_game_state(game_state)

    while True:
        # blocking input
        var inval = InputEvent(renderer.p_win[].wait_for_input())
        log[].append_msg("key pressed")
        if inval == InputEvent.KEY_RESIZE:
            renderer.update_window_rect()
            renderer.clear()
            renderer.draw_term_rect()
            renderer.draw_board_rect()
            instructions[].render_in_rect(renderer.get_instruction_rect())
            log[].render_in_rect(renderer.get_log_rect())
            renderer.draw_game_state(game_state)

        elif inval == InputEvent.KEY_Q_LOWER or inval == InputEvent.KEY_Q_UPPER:
            break

        else:
            input_processor.handle_input(inval, game_state)
            log[].render_in_rect(renderer.get_log_rect())
            renderer.draw_game_state(game_state)


# add a grid map in the renderer mapping cell -> location so that we can give a cell address, and update a location.
# Split left right halves of the terminal plane, right side has text ox with 2 lines - active player has a star next to them.
# Left side has the board.
# Movement updates cursor position, enter redraws board + advances play state.
