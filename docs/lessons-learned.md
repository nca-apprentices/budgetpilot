# Lessons learned

From the React Native proof of concept and from setting this repo up. The
model notes hold for LLMs generally, or for Gemma 4 E2B-it specifically.

## Model and AI

1. **RAM is the real limit.** A 2.5 GB on-device model can fail to load on a
   4 GB iPhone. Check RAM need against the target hardware, not download size.
2. **Image quality drives recognition.** Compression and blur measurably hurt
   reading fine print on receipts.
3. **Implicit conversation state contaminates answers.** Some APIs keep a
   running conversation, so an independent call inherits earlier history.
   Reset explicitly per request.
4. **Strict output formats get ignored.** "JSON only" failed even with a clean
   context. Ask for a fault-tolerant format, or use the API's structured
   output.
5. **The model invents numbers even when only rephrasing given ones.** Mark
   any model-written text containing numbers as "AI, please verify".
6. **Small multimodal models misread receipt photos.** Run OCR first (Apple's
   Vision, `VNRecognizeTextRequest`) and pass the text, not the image.
7. **OCR order is not reading order.** Words arrive column-wise, so "TOTAL"
   and its amount drift apart. Rebuild lines from bounding-box positions
   first — no prompt repairs an association lost structurally.
8. **Several plausible numbers, wrong pick.** Given two real totals in
   different currencies the model chose the wrong one. State domain rules
   ("prefer CHF") explicitly.
9. **Thinking budget eats the answer budget.** Both share one token limit. Cap
   thinking and raise the output limit together.
10. **Thinking mode did not improve image understanding** in our tests.
    Measure before assuming.
11. **Tune the assistant on the Mac, not the phone.** `mise run eval` runs
    the app's prompt, tools and `BudgetIntent` checks against Gemma 4 E2B on
    the Mac's GPU in about a second per message; `-- --chat` talks to it
    live. The phone is still the place to check speed and memory.
12. **Stopping the stream at a tool call erases the turn.** `ChatSession`
    then rolls the whole turn back, so the model never knew what it had
    added and "the lunch was 23.50" had nothing to refer to. Read the stream
    to the end and send the app's reply as the tool result with the next
    message.
13. **Small wording changes flip whole cases.** One clause fixed one case and
    broke another, and examples written like calls (`add_expense(...)`) made
    the model print calls as text. Judge a prompt on messages it was not
    tuned on, not only on the fixed cases.
14. **"Needs title, amount and category" makes the model ask for the
    category.** Making `category` optional (the app files it under other)
    and saying "never ask for a category" fixed it.
15. **Gemma 4's thinking text has no parser in mlx-swift-lm.** With thinking
    on, `<|channel>thought…<channel|>` lands in replies, and it was about
    five times slower for no better tool calls. It is off.

## This repo

1. **Nothing from the POC applies.** That was React Native. This is native
   Swift via XcodeGen and mise, driven from the terminal — no `pod install`,
   no `.xcworkspace`.
2. **Ask before giving GUI instructions.** Speculative Xcode click-throughs
   went wrong repeatedly, and the project runs from the terminal anyway.
3. **If `xcode-select` points at the Command Line Tools**, `xcodebuild` and
   `xcodegen` fail, and `sudo xcode-select -s` needs admin rights. Without
   sudo, set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` per
   command. `xcode-select -p` shows which one is active.
4. **MLX does not run in the iOS Simulator.** It aborts with a libc++
   hardening assertion (`basic_string(const char*) detected nullptr`) because
   the simulator's Metal device has no architecture name. MLX's own
   troubleshooting docs say so. `AssistantModel` throws under
   `#if targetEnvironment(simulator)` before downloading the model; test the
   assistant on a real device.
