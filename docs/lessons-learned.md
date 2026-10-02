# Lessons learned

Carried over from the proof of concept (`budgetpilot-proof-of-concept`,
React Native) and from setting this repo up.

## About the model/AI (independent of the tech stack)

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

## About this project's setup

1. **This project setup is completely different from the POC — don't mix them
   up.** The POC was React Native with `npx react-native run-ios`. This
   project is native Swift, set up with XcodeGen and mise, deliberately
   terminal-driven. Xcode GUI workflows from the POC (such as `pod install`
   or opening an `.xcworkspace`) do not apply here.
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
