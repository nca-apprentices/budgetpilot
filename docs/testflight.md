# TestFlight

Releases are built and uploaded by
[`release.yml`](../.github/workflows/release.yml) when a GitHub release is
published. Set up as in netgrade: same Apple team, manual signing with a
named provisioning profile, fastlane for build and upload.

## One-time Apple setup

1. **Bundle id** — register `ch.nca.budgetpilot` in the developer portal
   (Certificates, Identifiers & Profiles → Identifiers).
2. **App record** — create the app in App Store Connect with that bundle id.
3. **Distribution certificate** — reuse the team's Apple Distribution
   certificate if you have the `.p12`; create one otherwise.
4. **Provisioning profile** — an App Store profile for the bundle id, named
   exactly `budgetpilot-provisioning`. The name is referenced in
   `project.yml` and in the workflow, so a different name breaks the build.
5. **App Store Connect API key** — Users and Access → Integrations → create
   a key with the App Manager role. Note the key id and issuer id, and keep
   the `.p8`; it can only be downloaded once.

## Repository secrets

Settings → Secrets and variables → Actions:

| Secret | Value |
| --- | --- |
| `APPLE_DIST_CERT_P12` | distribution certificate as base64 |
| `APPLE_DIST_CERT_PASS` | its export password |
| `IOS_PROVISION_PROFILE` | `budgetpilot-provisioning.mobileprovision` as base64 |
| `APP_STORE_CONNECT_API_KEY_ID` | key id |
| `APP_STORE_CONNECT_ISSUER_ID` | issuer id |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | contents of the `.p8` file |
| `APPLE_ID` | Apple ID of the account |
| `APP_IDENTIFIER` | `ch.nca.budgetpilot` |
| `TEAM_ID` | Apple developer team id |

Base64 for the binary files:

```bash
base64 -i dist.p12 | pbcopy
base64 -i budgetpilot-provisioning.mobileprovision | pbcopy
```

## Releasing

Publish a GitHub release whose tag carries version and build number:

```
v0.1.0-1
```

The workflow strips the `v`, uses `0.1.0` as the marketing version and `1`
as the build number. **Every upload needs a higher build number** — App Store
Connect rejects a repeat. A non-numeric build part (`v0.1.0-beta2`) falls back
to a timestamp.

The release body becomes the TestFlight changelog.

## Running it locally

```bash
bundle install
bundle exec fastlane ios release version:0.1.0-1
```

The same environment variables as above have to be set, and the certificate
and profile have to be installed in the local keychain.

## Internal vs. external testers

The lane uploads for **internal** testers by default — team members with an
App Store Connect role, no review needed, build available within minutes.

External testers need a tester group named `nca` on this app and a review of
the first build. Once the group exists:

```bash
bundle exec fastlane ios release version:0.1.0-1 external:true
```

## Why the build settings look the way they do

`project.yml` signs only the `release` configuration. `debug` stays unsigned
so simulator builds and CI need no certificate. `MARKETING_VERSION` and
`CURRENT_PROJECT_VERSION` in `project.yml` are only fallbacks — fastlane
passes the real values per build, because the generated `.xcodeproj` is not
committed and would lose anything written into it.

`DEVELOPMENT_TEAM` is not in the repository. `project.yml` reads it from the
environment and fastlane sets it from the `TEAM_ID` secret, so a release
build needs that secret present. A local `fastlane ios release` therefore
needs `TEAM_ID` exported too; it stops with a clear message if it is
missing.
