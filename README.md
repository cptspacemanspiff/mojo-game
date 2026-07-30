# Tic Tac Toe in Mojo

So this is a basic tic-tac-toe terminal game written in mojo.

Mojo is a systems language (like rust or c++), but has python like semantics. It is new, and is still missing fundemental features for a systems language... Like threads... That being said I have been working on implementing a CPU FFT library in Mojo, but have been using AI. I figured I would try to get a feel for the language since I needed to write something without AI to begin with.

## How to build

The bazel code in the repository is cruft code completion help for the ncurses FFI headers.

This uses pixi: https://pixi.prefix.dev/latest/installation/

after that clone the repo, and in the repo root run:

```
pixi run game
```

That will start the game.

## Explanation of how it works:

So for this project you can think of it like a C or C++ terminal game, just useing basic ncursesw. The only difference is that I have to explicitly create a FFI wrapper function for every C ncurses function I need to use.

