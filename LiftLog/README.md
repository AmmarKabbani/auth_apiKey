# LiftLog 🏋️

A simple, native iPhone app to follow your 4-day Upper/Lower split and log every
session — built so you always know the number to beat.

## Features

- **4 preloaded days** — Upper A, Lower A, Upper B, Lower B with your exact exercises and rep schemes.
- **Fast logging** — every set is pre-filled with last session's weight × reps, so you only match or beat it.
- **Rest timer** — auto-starts when you tick off a set.
- **Progress charts** — top-set weight over time and a personal-record badge per exercise (Swift Charts).
- **History** — every completed session, browsable by date.
- **kg / lb toggle** — switch units anytime in Settings; existing logs convert automatically (stored in kg internally).
- **Private & offline** — all data stays on-device via SwiftData. No account, no network.

## Design

Dark, athletic theme with an electric-lime accent. Numbers are the hero of the
logging screen. Full design notes were delivered before the build.

## Tech

- SwiftUI + SwiftData + Swift Charts
- iOS 17+, iPhone, portrait
- No third-party dependencies

## Run it

1. Open `LiftLog.xcodeproj` in **Xcode 16** or newer.
2. Select an iPhone simulator (or your device).
3. Press ⌘R.

## Project layout

```
LiftLog/
├─ LiftLogApp.swift          App entry + SwiftData container
├─ Models/
│  ├─ Program.swift          Static 4-day program data
│  ├─ WorkoutModels.swift    WorkoutSession + SetLog (@Model)
│  └─ WeightUnit.swift       kg/lb conversion
├─ Theme/
│  └─ Theme.swift            Colors, Card component
└─ Views/
   ├─ RootTabView.swift      Tab bar
   ├─ HomeView.swift         Pick a day
   ├─ WorkoutDetailView.swift Exercise list + Start
   ├─ LoggingView.swift      Core logging + rest timer
   ├─ HistoryView.swift      Past sessions
   ├─ StatsView.swift        Progress charts
   └─ SettingsView.swift     Units, rest, data
```

## Customizing the program

Edit `Models/Program.swift` — each day is a `WorkoutDay` with a list of
`ProgramExercise(name, sets, repLow, repHigh)`. Change names, sets, or rep
ranges and the whole app updates.
