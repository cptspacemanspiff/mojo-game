#include <curses.h>
#include <locale.h>
#include "ncurses_shim.h"

void *mgs_stdscr(void) { return (void *)stdscr; }
int mgs_getch(void) { return getch(); }
int mgs_cols(void) { return COLS; }

/* Only compiles if NCURSES_WIDECHAR actually reached this translation unit:
   cchar_t and wadd_wch exist only in the wide half of curses.h. */
int mgs_add_wch_probe(void) {
  cchar_t cc;
  wchar_t w[2] = {L'x', L'\0'};
  setcchar(&cc, w, A_NORMAL, 0, NULL);
  return wadd_wch(stdscr, &cc);
}

// setlocale(int category, const char *locale);
// initscr();
// endwin();

wgetdelay(const WINDOW *)

wget

// cbreak


wtimeout(WINDOW *, int)


// curs_set(Int 
// wtimeout()
// keypad(WINDOW *, bool)