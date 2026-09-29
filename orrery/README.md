# Orrery

An animated solar system screensaver for *xscreensaver*, written in Free Pascal.

A glowing sun, six planets (one ringed, one with a moon), an asteroid belt, a comet on an elliptical Keplerian orbit and a twinkling starfield, seen from a tilted viewpoint and drawn with depth ordering.

This program was written by Claude, an AI model by Anthropic, using Claude Code.

## Requirements

- [Free Pascal](https://www.freepascal.org/)
- Xlib
- [AggPas](https://github.com/graemeg/fpGUI) (the copy shipped with fpGUI, in `src/corelib/render/software`)

## Build

```
make
```

If AggPas is not in the default location, set its path:

```
make AGGPAS=/path/to/aggpas
```

Add `DEBUG=1` for a debug build.

## Usage

Run `./orrery` to open it in a window (press Escape to quit).

When the `XSCREENSAVER_WINDOW` environment variable is set, the program draws into that window, as xscreensaver expects.
