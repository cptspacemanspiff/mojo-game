#ifndef NCURSES_SHIM_H
#define NCURSES_SHIM_H
void *mgs_stdscr(void);
int mgs_getch(void);
int mgs_cols(void);
int mgs_add_wch_probe(void);
#endif
