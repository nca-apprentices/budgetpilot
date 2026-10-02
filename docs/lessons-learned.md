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
