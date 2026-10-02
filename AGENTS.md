# AGENTS.md

Native iOS app (Swift/SwiftUI), driven from the terminal. See
[docs/product.md](docs/product.md) for what we are building and
[docs/lessons-learned.md](docs/lessons-learned.md) for what the proof of
concept taught us.

## Commands

```bash
mise run build    # generate the Xcode project and build it
mise run test     # run unit tests
mise run lint     # SwiftLint
mise run format   # SwiftFormat, writes changes
mise run run      # build, boot a simulator and launch the app
```

`mise tasks` lists the rest. Run `format` and `test` before opening a pull
request; CI runs the same tasks.

## Layout

| Path | Contents |
| --- | --- |
| `project.yml` | XcodeGen definition — the only place to change build settings |
| `Sources/BudgetPilot/` | app code; `Components/` for views, `Theme/` for the palette |
| `Tests/BudgetPilotTests/` | unit tests |
| `config/mise/tasks/` | one script per task |

`BudgetPilot.xcodeproj` is generated from `project.yml`, is not committed and
must never be edited by hand.

## Conventions

- Tests use **Swift Testing** (`@Test`, `#expect`), not XCTest.
- Colours come from the `Color` extension in `Theme/`, never as literals in
  views.
- SwiftLint and SwiftFormat cover `Sources/` and `Tests/`.
- `main` is protected: someone else approves your pull request, CI has to
  pass.
