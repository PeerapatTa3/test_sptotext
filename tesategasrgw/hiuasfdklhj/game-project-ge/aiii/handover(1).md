# Handover - Godot 4.7.2 Web STT

## Goal and architecture

Target: Godot 4.7.2 Web export hosted on GitHub Pages.

The implementation uses this flow:

```text
Browser microphone
    -> Web Speech API (SpeechRecognition)
    -> JavaScriptBridge
    -> SpeechManager autoload
    -> player.gd command parser
    -> player movement
```

The browser-specific code stays inside `speech/speech_manager.gd`. Gameplay only receives the `speech_result` signal and does not call JavaScript directly.

## Already implemented

### Speech manager

`speech/speech_manager.gd` now:

- Detects `SpeechRecognition` and `webkitSpeechRecognition`.
- Uses `en-US` recognition.
- Exposes `start_listening()` and `stop_listening()`.
- Emits `speech_result`, `speech_error`, `listening_started`, and `listening_stopped`.
- Reports unsupported browsers and microphone/recognition errors.
- Avoids crashing when the browser rejects duplicate start or stop calls.

### Project wiring

`project.godot` now contains:

```ini
[autoload]

SpeechManager="*res://speech/speech_manager.gd"
```

This makes `SpeechManager` available globally to `player/player.gd`.

The `voice_listen` input action is also configured with the `V` key. Holding `V` starts recognition; releasing `V` stops it.

### Voice commands

`player/player.gd` currently understands:

- `forward`, `move forward`, `go forward`
- `back`, `backward`, `move backward`, `go backward`
- `left`, `move left`, `go left`
- `right`, `move right`, `go right`
- `stop`, `stop moving`, `halt`

Keyboard movement remains available as a fallback.

## How to use it in Godot

1. Open the folder containing `project.godot` in Godot 4.7.2.
2. Open Project > Project Settings > Globals > Autoload.
3. Confirm that `SpeechManager` points to `res://speech/speech_manager.gd` and is enabled.
4. Open Project > Project Settings > Input Map.
5. Confirm that `voice_listen` has the `V` key assigned.
6. Run the project normally to verify keyboard movement.
7. Export a Web build before testing speech recognition. The browser bridge only runs when `OS.has_feature("web")` is true.

## How to test speech recognition

Use a browser that supports the Web Speech API, preferably a current Chromium-based browser.

1. Open the exported Web build from `localhost` or an HTTPS site.
2. Allow microphone access when prompted.
3. Hold `V` and say one command, such as `forward`.
4. Release `V`.
5. Confirm that the player moves in the requested direction.
6. Say `stop` to stop voice movement.
7. Test denied microphone permission and an unsupported browser.
8. Confirm keyboard movement still works when speech recognition is unavailable.

Microphone access may fail when the build is opened directly as a local `file://` page. Use a local HTTP server or GitHub Pages instead.

## Remaining work

1. Add an in-game status label for unavailable browsers, microphone permission errors, and listening state.
2. Confirm whether commands should remain English (`en-US`) or change to Thai, then update the recognition language and command vocabulary.
3. Improve normalization for punctuation, repeated spaces, and browser transcript variations.
4. Export the final Web build and test the deployed GitHub Pages HTTPS URL.
5. Document the supported browser and final command list for players.

## Important constraints

- Do not put cloud STT credentials in the client export.
- Do not move JavaScript calls into gameplay scripts.
- Do not rely on native/GDExtension microphone APIs for the GitHub Pages build.
- If browser speech recognition is unreliable, use a protected backend or browser-side Whisper/WASM as a later alternative.
