from tui.window import Window, Rect

from std.collections import List


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

    def get_owned_by(self, player_id : Int) -> Bool:
        if self._value == player_id:
            return True
        return False

struct GameRenderer(Movable):
    var win : Window

    def __init__(out self):
        # Construct a window, to create a terminal to render in.
        win = Window()



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
            ref cell = self.game_board[max_index-index][max_index-index]
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


def main() -> None:
    print("hello world")
    var w = Window()
    w.write_string("game window\n")
    w.wait_for_input()
    w.write_string("game window2\n")
    w.write_string(String(w.get_window_shape()))
    w.wait_for_input()

    var term_rect = w.get_window_shape()

    var sub_rect = Rect(7, 7, 4, 4)

    w.draw_rect_border(term_rect)
    w.draw_rect_border(sub_rect)
    w.wait_for_input()
