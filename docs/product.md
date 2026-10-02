# Product

## Background

A React Native proof of concept showed that on-device expense recognition
works: a local LLM pulled expenses out of free text and receipts reliably.
This repo is the real app, rebuilt in native Swift/SwiftUI. Nothing technical
carries over.

## What it does

Keeps a personal budget in one place — income, fixed costs, planned purchases,
money others owe you. AI helps where it saves time, never where trust matters:
amounts come from your input or a real price lookup, never from an estimate.

## Features

Not a fixed scope. The skeleton comes first, the rest is decided as we go.

1. **Budget & income** — remaining budget at a glance, warning before an
   overrun. Monthly savings goal with progress, history split into fixed vs.
   variable costs.
2. **Expense capture** — describe an expense or photograph a receipt; the app
   proposes amount, category and frequency. Nothing is saved until you
   confirm, and shaky guesses are marked as such.
3. **Calendar** — expenses and due debts per month; tapping a day pre-fills
   the date.
4. **Debts owed to you** — due date, calendar marker, reminder. Marking one
   received adds it to that month's budget.
5. **Price lookup** — a real market price for a planned purchase.
6. **Wishlist** — planned purchases, each toggleable in or out of the plan.
   Buying one converts it to an expense on the purchase date.
7. **Summary & export** — a readable summary to share or keep.
8. **Everything correctable** — AI-suggested values stay editable, and the app
   records what you fixed by hand.

## First milestone

Chat-based entry: type "Sony XM5 headphones for 299", the AI picks out amount
and category, books it, reports what is left. Dropdowns switch the same input
bar to price search or expense analysis. Voice input and receipt upload
alongside. A budget tab shows the month: available, percent spent, income,
fixed costs, recent expenses.

Quality counts as much as function — usability, speed, how understandable the
AI answers are. One feature finished properly beats three half-done.

## Rules

- **AI proposes, the user decides.** No silent automatic bookings.
- **The past is immutable.** Ending or changing a recurring item must not
  touch months already passed. A real retroactive change is a separate,
  deliberate step.
- **Show uncertainty.** A shaky recognition has to look shaky.
- **No estimated amounts.** Own input or a real price lookup.
- **Privacy first.** Process financial data locally where possible.
