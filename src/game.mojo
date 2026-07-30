from tui.window import Window, Rect
from tui.inputs import InputEvent


from std.collections import List
from std.memory import ArcPointer


@fieldwise_init
struct Player:
    var glyph: UInt
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


struct GameRenderer(Movable):
    var p_win: ArcPointer[Window]

    def __init__(out self, p_window: ArcPointer[Window]):
        # Construct a window, to create a terminal to render in.
        self.p_win = p_window

    def draw_term_rect(mut self):
        var window_rect = self.p_win[].update_window_shape()
        self.p_win[].draw_rect_border(window_rect)

    def draw_board_rect(mut self):
        # create a centered game board rectangle:
        var window_rect = self.p_win[].update_window_shape()

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

        # self.p_win[].


struct GameState:
    # Row major:
    var game_board: List[List[CellState]]
    var current_turn_player: Player

    def play(mut self, row: Int, col: Int) raises:
        ref state = self.game_board[row][col]
        if state != CellState.Free:
            raise Error("Cell already owned by a player")
        if self.current_turn_player.id == 1:
            state = CellState.Player1
        elif self.current_turn_player.id == 2:
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


struct InputProcessing:
    var p_win: ArcPointer[Window]

    def __init__(out self, p_window: ArcPointer[Window]):
        # Construct a window, to create a terminal to render in.
        self.p_win = p_window

    def handle_input(self):
        pass


def main() -> None:
    print("Tic-Tac-Toe 🌊")

    win_ptr = ArcPointer[Window](Window())
    renderer = GameRenderer(win_ptr)
    renderer.draw_term_rect()
    renderer.draw_board_rect()

    while True:
        var inval = InputEvent(renderer.p_win[].wait_for_input())
        if inval == InputEvent.KEY_RESIZE:
            renderer.draw_term_rect()
            renderer.draw_board_rect()
        elif inval == InputEvent.KEY_Q_LOWER or inval == InputEvent.KEY_Q_UPPER:
            break
