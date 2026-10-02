# BudgetPilot

A native iOS app for personal budget planning, built with Swift and SwiftUI.

The project is driven entirely from the terminal — Xcode itself is only needed
for the iOS SDK, the simulator and SwiftUI previews, never to build or run.

## Prerequisites

- **Xcode** — required for the iOS SDK, simulator and `xcodebuild`.
- **[mise](https://mise.jdx.dev/)** — installs every other tool and runs all
  project tasks. See below.

Everything else (XcodeGen, SwiftLint, SwiftFormat) is pinned in
[`mise.toml`](mise.toml) and installed by mise, so no manual `brew install`
steps and no version drift between machines or CI.

### Installing mise

```bash
curl https://mise.run | sh
```

The installer places mise in `~/.local/bin` but deliberately does **not** touch
your shell config, so a new shell will not find it yet — `mise: command not
found` at this point is expected. Activate it once (zsh is the macOS default):

```bash
echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc
```

For bash, append the `activate bash` equivalent to `~/.bashrc` instead. Then
open a new terminal, or `source` the file you just edited.

Activation does two things: it puts `mise` itself on your `PATH`, and it makes
the versions pinned in `mise.toml` take precedence over anything installed via
Homebrew — so `swiftlint` and `swiftformat` in your shell are the same versions
CI runs.

Check that it worked; `activated` and `shims_on_path` should both say `yes`:

```bash
mise doctor
```

## Getting started

```bash
mise install      # install the pinned toolchain
mise run build    # generate the Xcode project and build it
```

CI needs none of this setup — [`ci.yml`](.github/workflows/ci.yml) uses
[`jdx/mise-action`](https://github.com/jdx/mise-action), which installs and
activates mise on the runner.

## How the project is laid out

| Path | Purpose |
| --- | --- |
| `project.yml` | XcodeGen project definition (targets, build settings) |
| `mise.toml` | pinned tool versions and all project tasks |
| `Sources/BudgetPilot/` | app source code |
| `Tests/BudgetPilotTests/` | unit tests |
| `scripts/pick-simulator.sh` | resolves the newest available iPhone simulator |
| `.github/workflows/ci.yml` | CI pipeline |

`BudgetPilot.xcodeproj` is generated from `project.yml` by XcodeGen. It is
**not** committed and must never be edited by hand — change `project.yml` and
re-run `mise run generate` instead.

## Tasks

```bash
mise run generate       # generate BudgetPilot.xcodeproj from project.yml
mise run build          # generate, then build for the simulator
mise run test           # generate, build and run unit tests
mise run run            # build, boot a simulator and launch the app
mise run lint           # SwiftLint over Sources/ and Tests/
mise run format         # SwiftFormat, writes changes
mise run format-check   # SwiftFormat in lint mode (used by CI, changes nothing)
mise run simctl-reset   # shut down all running simulators
mise run clean          # remove the generated project and build output
```

Run `mise tasks` to list them with descriptions.

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push to
`main` and on every pull request, on a macOS runner: lint, format check, build
and test. It uses the same `mise run …` tasks as local development, so a green
CI run means the same commands pass locally.

There is no signing and no deployment — the pipeline only builds and tests
against the simulator.

## Contributing

`main` is protected: changes land through a pull request that is reviewed and
approved by someone else, and CI has to pass. Direct pushes to `main` are
rejected.

1. Branch off `main`.
2. Before opening a pull request, run `mise run format` and `mise run test`.
3. Open a pull request and request a review.

## Where Xcode's GUI is still needed

- **SwiftUI previews** (`#Preview`) — only render in the Xcode canvas.
- **Signing for a physical device** — signing is disabled for simulator builds
  (`CODE_SIGNING_ALLOWED: NO`). Running on a real iPhone needs a development
  team and certificate, set up once through Xcode.

Everything else — building, testing, running in the simulator — works entirely
from the terminal.
