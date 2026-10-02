# BudgetPilot

A native iOS app for personal budget planning, built with Swift and SwiftUI.

The project is driven entirely from the terminal — Xcode itself is only needed
for the iOS SDK, the simulator and SwiftUI previews, never to build or run.

## Getting started

Install Xcode and [mise](https://mise.jdx.dev/getting-started.html). Make sure
you also run mise's shell activation step, otherwise your shell will not find
the `mise` command. Then:

```bash
mise install      # install the pinned toolchain
mise run build    # generate the Xcode project and build it
```

`mise tasks` lists everything else you can run. Tool versions are pinned in
[`mise.toml`](mise.toml) and CI runs the same tasks, so green locally means
green in CI.

See [AGENTS.md](AGENTS.md) for the repo layout and conventions,
[docs/product.md](docs/product.md) for what we are building.

## Contributing

`main` is protected: changes land through a pull request that is reviewed and
approved by someone else, and CI has to pass.

1. Branch off `main`.
2. Before opening a pull request, run `mise run format` and `mise run test`.
3. Open a pull request and request a review.

## Where Xcode's GUI is still needed

- **SwiftUI previews** (`#Preview`) — only render in the Xcode canvas.
- **Signing for a physical device** — signing is disabled for simulator builds
  (`CODE_SIGNING_ALLOWED: NO`). Running on a real iPhone needs a development
  team and certificate, set up once through Xcode.
