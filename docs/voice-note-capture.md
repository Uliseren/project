# Dictating the receipt note

**Status: decided 2026-09-11 — option C.** Voice input is the keyboard's own
dictation, announced by a hint line under the note field. No mic button and
no transcription endpoint exist; B is only on the table if C falls short.

What the receipt note is and how it reaches the classifier lives in
`back/RECEIPT_OCR.md` → "User note". This document only covers how to
*dictate* it instead of typing it.

## The question

Transcribe in the phone's browser, so the back never receives or processes
audio, or upload the audio and transcribe it in the back?

## What decides it

- **Both phones.** Héctor uses Chrome on Android, Victoria an iPhone. An
  option that fails on the iPhone is out, however well it works on Android.
- **It runs as an installed app.** The front is a PWA added to the home
  screen (`display: "standalone"` in `front/src/app/manifest.ts`). On iOS a
  home-screen app is not a Safari tab, and the worst bugs below only show up
  there.
- **Short Spanish text**: one or two sentences, 500 characters at most.
- **The transcript is read before it counts.** A misheard word is not a typo
  here, it is a hint that steers the categories. Whatever produces the text,
  it lands in the note field, where the user sees and edits it before
  sending.

## Option A — Web Speech API in the browser

- **Android Chrome: works, but not on the phone.** `SpeechRecognition` is
  exposed (unprefixed since Chrome 139), and recognition runs on Google's
  servers: "your audio is sent to a web service" ([MDN][mdn]). Chrome's
  on-device mode (`processLocally`, [Chrome 139][chrome139]) is desktop-only;
  the [compat data][bcd] marks it unsupported on Android. So "no audio in our
  back" does not mean the audio stays on the phone.
- **iPhone: no, at best flaky. This is what rules A out.**
  - Safari only has the prefixed `webkitSpeechRecognition` (iOS 14.5+), a
    wrapper over Apple's native recognizer ([WebKit docs #120][wk120]), which
    on iOS 17+ refuses to run with Siri and Dictation disabled
    ([Apple forums 739006][af739006]; that Safari inherits this is inferred,
    not tested).
  - It is reported to work in a Safari tab and fail once the page is added
    to the home screen, across iOS versions ([Apple forums 748048][af748048],
    2024-03, unanswered). That is exactly how the app is used. No WebKit
    release note from [26.2][wk262] to [26.6][wk266] or the [27 beta][wk27]
    mentions a fix, and no 2025–2026 report says it works now.
  - Other reports: results stop after the first phrase with no `onend` or
    `onerror` ([web-speech-api #96][ws96], 2021); `interimResults` silently
    degrading to final-only ([#120][wk120], 2025, no WebKit reply).
  - Chrome on iOS runs on WebKit and exposes the object without it working
    ([WebKit bug 239816][wk239816], title only, status not verified).
- **Firefox:** behind a pref, off by default. **Standard:** still a W3C
  Community Group draft ([spec][spec], 2026-09-09).
- **Work, if chosen anyway:** front only, about half a day. Cheap to build,
  but it ships a mic button that fails for half the household.

## Option B — record in the browser, transcribe in the back

- **Recording:** `MediaRecorder` on both phones. Chrome records `audio/webm`
  (Opus); Safari defaults to `audio/mp4` (AAC) and records WebM/Opus when
  asked since [18.4][wk184] ([summary][mrsupport], 2026-07). OpenAI and Groq
  both accept webm, mp4 and m4a. Older threads report OpenAI rejecting
  Safari's mp4 ([2023][oaimp4a], [2024][oaimp4b], both before 18.4), so ask
  Safari for WebM first.
- **Transcription** (prices fetched 2026-09-11):

  | Model | Price | A 15 s note |
  |---|---|---|
  | OpenAI `gpt-transcribe` — recommended in [OpenAI's guide][oaistt], takes language and keyword hints | $0.0045/min | ~$0.001 |
  | OpenAI `gpt-4o-mini-transcribe` | ~$0.003/min | ~$0.0008 |
  | Groq `whisper-large-v3-turbo` — what voice-momo already uses | $0.04/h, 10 s minimum | ~$0.0002 |

  Even dictating a note on ten tickets a day, the priciest of the three is
  about $4 a year ([OpenAI pricing][oaiprice], [Groq][groq]). A short clip
  comes back in about a second. Groq is faster and cheaper, but it would be a second
  provider and key for a difference of cents; the back already has an
  OpenAI key.
- **What it adds:**
  - One synchronous endpoint: audio in, text out. The clip is read in
    memory, sent and dropped. No model, no migration, no media folder, no
    cleanup job. A 30-second clip is well under 1 MB.
  - Why synchronous and not handed to the draft's background thread: the
    transcript has to be seen and corrected before it steers the classifier,
    and holding the audio for a later run would bring back the storage and
    cleanup this avoids.
  - The audio goes to OpenAI, which already receives every receipt photo.
- **The iPhone risk it keeps:** microphone access in iOS home-screen apps has
  its own report — recording works on first launch and fails after closing
  and reopening the app, until the phone restarts. A WebKit engineer
  answered "we had issues with getUserMedia not always working in PWA"
  ([Apple forums 797987][af797987], 2025-08). Weaker evidence than A's, but
  not disproven either, so B starts with a test on the real iPhone.

## Option C (intermediate) — the keyboard's own dictation

The note field is a plain `<textarea>`, so the keyboard microphone should
already work in it today: iOS Dictation ("dictate text anywhere you can type
it", on-device for many languages, needs *Enable Dictation* on —
[Apple Support][applesupport]) and Gboard voice typing on Android ("works in
any app that you can type with" — [Gboard Help][gboard]). Both quotes come
from search snippets; the pages themselves could not be opened.

- Zero code, zero cost, no audio reaching the back or a paid API, and
  on-device on the iPhone.
- It sidesteps both iOS problems above: it is the system keyboard, not
  `SpeechRecognition` or `getUserMedia`.
- Not tried on the real phones inside the installed app. No PWA-specific
  report against it turned up, which is an absence of evidence, not a test.
- The price is ergonomic: tap the field, then the keyboard's mic, instead of
  one dedicated button, and users have to know it is there.

## Discarded — Whisper running in the phone

WebGPU now ships on [iOS 26][wk26] and recent Android Chrome, so it is
possible, but even `whisper-base` is a [~77 MB download][hfbase] and the small
models are the weakest at Spanish. Tens to hundreds of megabytes of download
and memory on a phone, to save a tenth of a cent per note.

## Recommendation

**Don't build a mic button yet. Use C now; if a dedicated button is still
wanted after real use, build B. Not A.**

1. **Now, C.** Try the keyboard mic in the note field on both phones, inside
   the installed app, for a couple of weeks. If it works, this is solved at
   no cost. The field says so under it ("También puedes dictarla con el
   micro del teclado", in `front/src/components/generic/receipt-note-field.tsx`),
   because a feature nobody knows about is one nobody uses.
2. **If C falls short** — it fails inside the installed app on the iPhone, or
   the extra tap means nobody uses it — **B**. That is the answer to the
   question: transcribe **in the back**. The in-browser option is the one
   that fails on Victoria's iPhone, and on Chrome it sends the audio to Google
   anyway; the back option costs one stateless endpoint and about a tenth of
   a cent per note.
3. **Not A** unless WebKit fixes speech recognition in home-screen apps.
   Worth re-checking then, not before.

## Work if B is built

1. **Spike on the real iPhone first, ~1 hour, go/no-go.** A throwaway page in
   the installed app that records 10 seconds, then close the app, reopen it
   and record again. If the second recording fails, B is out for the iPhone
   too and C is the answer.
2. **Back, ~half a day.**
   `POST /api/v1/accounts/<id>/movements/receipt-note/transcribe/` —
   multipart `audio` (≤ 60 s; webm, mp4, m4a) → `{"text": "..."}`. OpenAI
   transcription with `language="es"` and the account's category names as
   keyword hints, model in an env var beside the OCR ones, tests with a fake
   client like the OCR tests, and a short section in `RECEIPT_OCR.md`.
3. **Front, ~1 day.** A mic button in `ReceiptNoteField`'s action slot:
   feature detection, recording with a visible timer and a 30-second cap,
   `audio/webm;codecs=opus` when supported, upload, transcript appended to
   the note for editing. On any failure, a message pointing at the keyboard
   mic. Tested on both phones inside the installed app.
4. **Infrastructure: none.** Same key, same server, nothing stored.

<!-- Sources (all fetched 2026-09-11 unless a date is given in the text) -->

[mdn]: https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition
[bcd]: https://github.com/mdn/browser-compat-data/blob/main/api/SpeechRecognition.json
[chrome139]: https://developer.chrome.com/blog/new-in-chrome-139
[spec]: https://webaudio.github.io/web-speech-api/
[wk120]: https://github.com/WebKit/Documentation/issues/120
[af739006]: https://developer.apple.com/forums/thread/739006
[af748048]: https://developer.apple.com/forums/thread/748048
[af797987]: https://developer.apple.com/forums/thread/797987
[ws96]: https://github.com/WebAudio/web-speech-api/issues/96
[wk239816]: https://bugs.webkit.org/show_bug.cgi?id=239816
[wk26]: https://webkit.org/blog/17333/webkit-features-in-safari-26-0/
[wk262]: https://webkit.org/blog/17640/webkit-features-for-safari-26-2/
[wk266]: https://webkit.org/blog/18178/webkit-features-for-safari-26-6/
[wk27]: https://webkit.org/blog/17967/news-from-wwdc26-webkit-in-safari-27-beta/
[wk184]: https://webkit.org/blog/16574/webkit-features-in-safari-18-4/
[mrsupport]: https://www.testmuai.com/learning-hub/mediarecorder-browser-support/
[oaimp4a]: https://community.openai.com/t/whisper-issues-with-mp4-saved-by-safari/545761
[oaimp4b]: https://community.openai.com/t/can-t-get-the-right-audio-format-for-recording-in-web-application-with-whisper-on-ios/1025933
[oaistt]: https://developers.openai.com/api/docs/guides/speech-to-text
[oaiprice]: https://developers.openai.com/api/docs/pricing
[groq]: https://console.groq.com/docs/speech-to-text
[applesupport]: https://support.apple.com/guide/iphone/dictate-text-iph2c0651d2/ios
[gboard]: https://support.google.com/gboard/answer/2781851
[hfbase]: https://huggingface.co/onnx-community/whisper-base/tree/main/onnx
