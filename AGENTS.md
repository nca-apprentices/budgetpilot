# AGENTS.md

Native iOS app (Swift/SwiftUI) for personal budget planning, driven entirely
from the terminal. Product background and feature plans live in
[docs/product.md](docs/product.md); lessons carried over from the proof of
concept are in [docs/lessons-learned.md](docs/lessons-learned.md).

## Commands

Everything runs through [mise](https://mise.jdx.dev/); see the
[README](README.md) for first-time setup.

```bash
mise run build    # generate the Xcode project and build it
mise run test     # run unit tests
mise run lint     # SwiftLint
mise run format   # SwiftFormat, writes changes
mise run run      # build, boot a simulator and launch the app
```

Run `mise run format` and `mise run test` before opening a pull request. CI
runs the same tasks, so green locally means green in CI.

## Layout

| Path | Contents |
| --- | --- |
| `project.yml` | XcodeGen definition — the only place to change build settings |
| `Sources/BudgetPilot/` | app code; `Components/` for reusable views, `Theme/` for the palette |
| `Tests/BudgetPilotTests/` | unit tests |
| `mise.toml` | pinned tool versions and every task |

`BudgetPilot.xcodeproj` is generated from `project.yml`, is not committed, and
must never be edited by hand.

## Conventions

- Unit tests use **Swift Testing** (`@Test`, `#expect`), not XCTest.
- Colours come from the `Color` extension in `Theme/`, never written as
  literals inside views.
- SwiftLint and SwiftFormat cover both `Sources/` and `Tests/`.
- `main` is protected: changes land through a pull request someone else
  approves, with passing CI. You cannot approve your own.
