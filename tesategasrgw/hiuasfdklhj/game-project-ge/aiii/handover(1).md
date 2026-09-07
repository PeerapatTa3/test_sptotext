# Handover — Godot 4.7.2 Web STT

## Current decision
Target: **Godot 4.7.2 HTML5 export hosted on GitHub Pages**.

Chosen STT architecture:
**Browser microphone → Web Speech API (`SpeechRecognition`) → JavaScript → Godot JavaScriptBridge → `SpeechManager` signal → gameplay.**

## Do next
1. Create `SpeechManager.gd`.
2. Add a small browser-side `speech.js` or custom HTML-shell integration.
3. Expose a clean Godot API:
   - `start_listening()`
   - `stop_listening()`
   - `speech_result(text)`
   - optionally `speech_error(error)`
   - optionally `listening_started` / `listening_stopped`
4. Connect gameplay only to `speech_result`.
5. Add a browser-support fallback.
6. Export to HTML5 and test on the target browsers.
7. Deploy the generated web build to GitHub Pages.

## Key implementation constraint
Do **not** make gameplay depend directly on JavaScript APIs. Keep browser-specific code inside `SpeechManager`/web bridge so another STT backend can be substituted later.

## If browser STT proves unreliable
Fallback options, in order:
1. Cloud STT through a protected backend.
2. Browser-side Whisper/WASM if offline/client-side recognition is required.
3. Avoid native/GDExtension STT as the primary GitHub Pages solution.

## Useful Godot concepts
- `OS.has_feature("web")`
- `JavaScriptBridge`
- Custom HTML shell for web exports
- Signals for delivering recognized text to gameplay

## Example gameplay contract
```gdscript
speech_manager.speech_result.connect(_on_speech)

func _on_speech(text: String) -> void:
    # Normalize and interpret the text here.
    pass
```
