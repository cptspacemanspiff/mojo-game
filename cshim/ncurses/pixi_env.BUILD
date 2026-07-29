"""Wide-character ncurses, as provided by the pixi environment.

Overlay BUILD for @pixi_env -- see the new_local_repository call in MODULE.bazel,
which points this repo at .pixi/envs/default. pixi.lock is the pin: the version
resolved there is the version built against, so there is no second place to bump.

This is the ONE non-hermetic seam in the build, and it is deliberate. Building
ncurses from //third_party/ncurses instead would NOT make the game self-contained:
the library is only half the dependency, because ncurses resolves the terminal at
runtime through the terminfo database (/usr/share/terminfo, or $TERMINFO). Going
from-source would still read the host's terminfo unless we also built tic,
compiled a terminfo tree and shipped it -- so it moves the host dependency rather
than removing it. //third_party/ncurses earns its place as reference source (which
parts of the API are macros) rather than as a build input.

If that calculus changes -- shipping to a machine with no pixi env, or needing
configure flags conda did not use -- the replacement is a rules_foreign_cc
configure_make over //third_party/ncurses, and ONLY this file changes:
//cshim/ncurses depends on the label @pixi_env//:ncursesw, not on how it is built.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

cc_library(
    name = "ncursesw",
    # Link the versioned files BY PATH instead of with -lncursesw. This is the
    # same decision pixi.toml's build task already makes, for the same reason:
    # `-lncursesw` resolves through the linker's search path, and on this host
    # /usr/lib64/libncursesw.so is a linker script that pulls in the NARROW
    # libtinfo. Mixing wide ncurses with narrow tinfo segfaults inside initscr(),
    # which is miserable to debug because it fails at the FIRST curses call rather
    # than at link time. Naming the files removes the search entirely.
    #
    # (The env's own lib/libncursesw.so is also a linker script, but a correct
    # one -- INPUT(libncursesw.so.6 -ltinfow), wide to wide. It is still not used
    # here: relying on it would mean relying on -L ordering putting the env ahead
    # of /usr/lib64, and that is exactly the fragility being designed out.)
    #
    # The .so.6 entries are symlinks to the current .so.6.x, so pointing at the
    # soname rather than the full version means routine pixi.lock patch bumps do
    # not require editing this file.
    srcs = [
        "lib/libncursesw.so.6",
        "lib/libtinfow.so.6",
    ],
    hdrs = glob(["include/ncursesw/**/*.h"]),
    # NCURSES_WIDECHAR is what turns on the wide half of curses.h (the add_wch /
    # cchar_t family). Without it the headers silently expose the narrow API while
    # the linked library is the wide one -- an ABI mismatch the compiler cannot
    # see. _GNU_SOURCE matches what the env's ncursesw.pc reports. Both are on
    # `defines` rather than `copts` so every consumer inherits them; a shim
    # compiled wide against a caller compiled narrow is the same bug one level up.
    defines = [
        "NCURSES_WIDECHAR=1",
        "_GNU_SOURCE",
    ],
    # ONLY include/ncursesw, deliberately NOT include/. The env ships a narrow
    # curses.h at include/curses.h alongside the wide one at
    # include/ncursesw/curses.h. Adding the parent to the search path would make
    # which header you get depend on -I ordering, so it is left out.
    includes = ["include/ncursesw"],
    visibility = ["//visibility:public"],
)
