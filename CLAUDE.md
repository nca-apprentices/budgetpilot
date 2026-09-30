# BudgetPilot (production app)

> Project context for this repo (`nca-apprentices/budgetpilot`). Contains the
> product idea and, further down, lessons learned from the project start —
> deliberately kept separate from the earlier proof of concept
> (`budgetpilot-proof-of-concept`, React Native).

## Background

BudgetPilot started as a proof of concept (React Native) meant to show that an
AI-assisted budget app with on-device expense recognition is technically
feasible. The POC confirmed that, among other things with reliable free-text
and receipt extraction using a local LLM. This project is the real,
production-minded app — set up from scratch, without carrying over the POC's
technical decisions. The platform is already fixed: native Swift/SwiftUI
instead of React Native, which is considered not future-proof enough for this
project.

## Product idea

BudgetPilot helps users keep their personal budget under control — income,
fixed costs, planned purchases and outstanding debts owed to them in one
place, with AI assistance where it genuinely saves time (capturing expenses
from free text or receipts), but never where trust is critical: the actual
numbers always come from reliable sources, never from an AI estimate.

## Core features (product view)

1. **Budget & income** — record monthly income, fixed costs and planned
   purchases; see the remaining budget (absolute and percentage) at a glance,
   with a warning when an overrun is likely. Plus a monthly savings goal (the
   amount you want to set aside this month) with a progress indicator, and a
   history view of recent months (fixed costs vs. variable expenses shown
   separately) so trends over time are visible, not just the current month.
2. **Capture expenses via free text or a receipt photo** — the user describes
   an expense in their own words or photographs a receipt; the app suggests
   amount, category and frequency, but must always have the result confirmed
   before anything is saved. Uncertain suggestions are clearly marked as such
   rather than presented as a certain result.
3. **Calendar view** — all expenses and due debts in a monthly overview;
   tapping a day opens the capture form pre-filled with that date.
4. **Debts owed to the user** — money the user is still owed by someone (for
   example money they fronted), with a due date, a calendar marker and a
   reminder on the due day. Once a debt is marked as received, the amount
   automatically flows into that month's remaining budget.
5. **Price comparison** — look up a realistic market price for a planned
   purchase, so budget planning isn't based on guesses.
6. **Wishlist for planned purchases** — collect planned purchases and toggle
   each one in or out of the current budget planning. When a planned purchase
   actually happens, the app converts it into a real expense — booked on the
   date of the actual purchase, not the date the purchase was originally
   planned.
7. **Summary & export** — a clear, traceable summary of the budget,
   exportable for sharing or keeping.
8. **Correctable everywhere** — every value suggested by the AI or imported
   can be edited or deleted later; the app clearly remembers what was
   manually corrected, so there's no guessing afterwards whether a value came
   from the AI or from the user.

## Development order: basics first, the rest open

The "core features" above describe the product vision, but they are **not a
fixed scope that has to be built one-to-one.** Only a basic skeleton gets
built first; after that we look at what makes sense to do next — none of it is
set in stone.

The first building block that development starts with:

- **Add expenses via chat:** enter free text (for example "Sony XM5
  headphones for 299") — the AI recognises amount and category, files the
  expense under the right budget and reports how much is left.
- **Search for best prices:** switch the same input bar from "add" to "price
  search" via a dropdown — the app then looks for the cheapest price for a
  product instead of recording an expense.
- **AI analysis:** use a second dropdown to have your own expenses analysed
  (for example where most money goes, where you could save).
- **Voice input and receipts:** dictate expenses via the microphone, talk to
  the AI directly via an audio button, upload a receipt or photo via "+".
- **Budget overview:** the budget tab shows the available budget for the
  month, the percentage already spent, income, fixed costs and the most
  recent expenses with category and date.

Everything else listed under "core features" (calendar, debts, wishlist,
savings goal/history and so on) is a target picture for later — whether and
when it actually gets built is decided during development.

**Minimal likable product, not just minimal viable product.** For these first
building blocks it matters not only that they work technically, but also how
well they are executed — usability, responsiveness, how understandable the AI
answers are. Better to finish one feature properly than to start several and
leave them all shallow.

## Guardrails from the POC (product-relevant, not technical)

- **The AI suggests, it never decides definitively.** Every automatically
  recognised number or category stays reviewable and correctable by the user
  before it is saved — no silent automatic bookings.
- **The past stays untouched.** When a recurring item (rent, a subscription)
  is ended or changed, months already past — including the one currently
  displayed — must not be affected retroactively. An "end from now on" must
  never silently alter history; a real, full retroactive change (for example
  to fix a data entry error) has to be a separate, deliberate step.
- **Make uncertainty visible instead of hiding it.** When the app isn't sure
  about a recognition, that must be clearly visible, not disguised as
  "probably right".
- **Prices and amounts never come from an AI estimate**, always from real,
  traceable sources (the user's own input or an actual market price lookup).
- **Privacy first:** financial data is sensitive — process it locally wherever
  possible instead of sending it to a server.

## Technical setup (current state)

Terminal-driven, deliberately using as little of the Xcode GUI as possible
(see `README.md` for the full explanation):

- `project.yml` (XcodeGen) describes the project. `BudgetPilot.xcodeproj` is
  generated from it and is **not** checked in — never touch it by hand.
- Code lives in `Sources/BudgetPilot/`, tests in `Tests/BudgetPilotTests/`,
  editable with any editor.
- [mise](https://mise.jdx.dev/) pins the toolchain (XcodeGen, SwiftLint,
  SwiftFormat) in `mise.toml` and provides every task:
  `mise run build` / `test` / `lint` / `format` / `format-check` / `run`.
  Run `mise tasks` for the full list. CI runs the same tasks, so a green CI
  run means the same commands pass locally.
- `scripts/pick-simulator.sh` resolves the newest available iPhone simulator,
  so nothing depends on a hardcoded device name that may not exist on a given
  Xcode install or CI runner.
- `main` is protected: changes land through a reviewed pull request with
  passing CI. Direct pushes to `main` are rejected, and you cannot approve
  your own pull request.

## Lessons learned about the model/AI (from the POC, independent of the tech stack)

These hold regardless of which model or platform is eventually chosen — they
are properties of LLMs in general, or of Gemma 4 E2B-it specifically, not
React Native bugs:

1. **RAM requirements are real.** An on-device model of around 2.5 GB like
   Gemma 4 E2B-it can fail to load on devices with little free RAM (for
   example an iPhone 12 with 4 GB total) because of OOM. Check a candidate
   on-device model's actual RAM requirement against the target hardware, not
   just its download size.
2. **Image quality directly affects photo recognition.** Heavier JPEG
   compression or blur measurably degrades how reliably a model reads fine
   print such as a receipt.
3. **Conversation state is a trap.** Some LLM APIs implicitly maintain an
   ongoing conversation, so each new and supposedly independent call ends up
   attached to the history of previous calls and returns contaminated
   answers. Reset or start fresh explicitly for every self-contained request
   instead of relying on implicit state.
4. **Models don't reliably follow strict format requirements.** "Reply with
   JSON ONLY" was occasionally ignored even with a clean context. Asking for
   a simpler, more fault-tolerant output format — or using the API's
   constrained/structured output — is more robust than fighting the model.
5. **The AI invents new numbers even when only rephrasing given ones.** Even
   when a prompt states exact numbers as fixed facts ("use only these
   values"), the model can produce different, invented numbers in prose. Any
   model-generated text containing numbers needs a visible "AI · please
   verify" marker; never trust it blindly.
6. **Small multimodal models read receipt photos unreliably when given the
   image directly.** Running dedicated OCR first (for example Apple's Vision
   framework, `VNRecognizeTextRequest`, usable directly from Swift) and
   passing the text to the model was considerably more reliable than handing
   the model the image.
7. **OCR text order does not match visual reading order.** Text recognition
   often returns words column by column rather than line by line, so a label
   and its value (for example "TOTAL" and the amount) can end up far apart in
   the recognised text. Fix: reconstruct lines from the recognition results
   by bounding-box position (group into rows by vertical position first, then
   sort horizontally) before passing them to the language model — no prompt
   can repair an association that was lost structurally.
8. **Given several plausible numbers, the model doesn't automatically pick
   the right one.** With two genuine totals in different currencies (a
   foreign-currency conversion on a card payment), the model picked the wrong
   one — both numbers were real, only the choice was wrong for the use case.
   Domain rules ("always prefer CHF") have to be stated explicitly in the
   prompt.
9. **Thinking/reasoning budget and answer budget compete for the same token
   limit.** An unlimited thinking budget can consume the entire output budget
   on a more complex request before the actual answer even begins. Cap the
   thinking budget *and* set the overall output limit generously enough — the
   two values belong together.
10. **"Thinking mode" is not a cure-all for image understanding.**
    Explicitly enabling thinking did not improve photo recognition accuracy
    in tests. Don't assume more reasoning automatically yields better
    multimodal results without measuring it.

## Lessons learned (project setup, this repo)

1. **This project setup is completely different from the POC — don't mix them
   up.** The POC was React Native with `npx react-native run-ios`. This
   project is native Swift, set up with XcodeGen and mise, deliberately
   terminal-driven (see above). Xcode GUI workflows from the POC (such as
   `pod install` or opening an `.xcworkspace`) do not apply here.
2. **When setting things up: correct, simple answers instead of complicated
   multi-step instructions.** The developer writes the code themselves and
   wants reliable, direct help from the AI — not long speculative GUI
   click-throughs that go wrong with every Xcode version difference. This
   happened on the first attempt: several rounds of incorrect Xcode dialog
   descriptions before it became clear the project should run through
   XcodeGen from the terminal anyway. When GUI instructions really are
   needed, ask briefly what the user currently sees instead of blindly
   prescribing several steps.
3. **If `xcode-select` points at the Command Line Tools instead of
   Xcode.app**, `xcodebuild` and `xcodegen` fail, and `sudo xcode-select -s`
   needs admin rights that may not be available. Workaround without sudo: set
   `DEVELOPER_DIR` per command, pointing at the installed Xcode:
   `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Check
   with `xcode-select -p` — on a correctly configured machine this is already
   the Xcode.app path and no workaround is needed.
