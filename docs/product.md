# BudgetPilot — product context

Background, product idea and feature plans for this repo. Deliberately kept
separate from the earlier proof of concept
(`budgetpilot-proof-of-concept`, React Native).

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
