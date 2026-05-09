# Caffeinate

A macOS menu bar app wrapping `/usr/bin/caffeinate` to keep your Mac awake on demand.

## Features

- One-click toggle from the menu bar
- Three modes — prevent idle sleep, prevent display sleep, prevent system sleep (combinable)
- Optional timer with countdown shown next to the menu bar icon
- Progress ring on the toggle button
- Activate on launch
- Launch at login (via `SMAppService`)
- Liquid Glass UI

## Install

```bash
brew tap mhjiang97/tap
brew install --cask caffeinate
```

## Build from source

```bash
git clone https://github.com/mhjiang97/Caffeinate.git
cd Caffeinate
open Caffeinate.xcodeproj
```

Then press **⌘B** to build or **⌘R** to build and run in Xcode.

Alternatively, build from the command line:

```bash
xcodebuild -project Caffeinate.xcodeproj -scheme Caffeinate -configuration Release build
```

## Usage

1. Launch Caffeinate — a cup-and-saucer icon appears in the menu bar
2. Click it to open the popover
3. Pick one or more modes (idle / display / system)
4. Optionally set a duration, then tap the cup to activate
5. Click the gear icon to configure menu bar countdown, progress ring, activate-on-launch, and launch-at-login

## License

[MIT](LICENSE)
