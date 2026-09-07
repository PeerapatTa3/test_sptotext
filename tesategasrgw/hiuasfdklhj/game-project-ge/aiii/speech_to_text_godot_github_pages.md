# Speech-to-Text — Godot 4.7.2 + GitHub Pages

## Goal
Implement speech-to-text (STT) for a Godot 4.7.2 game exported to HTML5 and hosted on GitHub Pages.

## Recommended approach
**Godot HTML5 → JavaScript bridge → browser Web Speech API → GDScript**

```text
Browser microphone
      ↓
SpeechRecognition
      ↓
recognized text
      ↓
JavaScript bridge
      ↓
Godot / GDScript
      ↓
game logic
```

## Why this approach
- No Whisper model needs to be shipped with the game.
- No STT server is required for the basic implementation.
- The browser handles microphone access and speech recognition.
- Godot only needs to receive recognized text.
- Keep speech code isolated behind a `SpeechManager`.

## Alternatives
| Approach | GitHub Pages suitability | Notes |
|---|---|---|
| Browser Web Speech API | ★★★★★ | Simplest; browser compatibility varies |
| Cloud STT API | ★★★★☆ | Better control/quality; use a backend to protect credentials |
| Whisper in browser | ★★★☆☆ | Client-side/offline potential; heavier |
| Native Godot STT addon | ★★☆☆☆ | Native dependencies are unsuitable for typical web exports |
| Record → cloud transcription | ★★★★☆ | Simple if realtime STT isn't needed |

## Suggested project layout
```text
project/
├── project.godot
├── scenes/
│   └── Main.tscn
├── scripts/
│   ├── speech_manager.gd
│   └── main.gd
└── web/
    ├── speech.js
    └── index.html
```

## JavaScript
Use `SpeechRecognition` / `webkitSpeechRecognition`, configure language and result handling, then forward the transcript to Godot.

```javascript
const SpeechRecognition =
    window.SpeechRecognition ||
    window.webkitSpeechRecognition;

const recognition = SpeechRecognition
    ? new SpeechRecognition()
    : null;

if (recognition) {
    recognition.lang = "en-US";
    recognition.continuous = false;
    recognition.interimResults = false;

    recognition.onresult = (event) => {
        const text = event.results[0][0].transcript;
        // Forward `text` to Godot through the JavaScript bridge/callback.
    };
}
```

## Godot
Keep the game-facing API simple:

```gdscript
extends Node

signal speech_result(text: String)

func start_listening() -> void:
    # Call the browser SpeechRecognition start() through JavaScriptBridge.

func stop_listening() -> void:
    # Call SpeechRecognition stop().

func _on_speech_result(text: String) -> void:
    speech_result.emit(text)
```

Gameplay then stays platform-agnostic:

```gdscript
speech_manager.speech_result.connect(_on_speech)

func _on_speech(text: String) -> void:
    match text.to_lower():
        "open inventory":
            open_inventory()
        "close inventory":
            close_inventory()
        "hello":
            say_hello()
```

## Important caveats
- Browser support for `SpeechRecognition` is inconsistent.
- Microphone permission must be granted by the user.
- Test the exact browsers you intend to support.
- Add a fallback when speech recognition is unavailable.
- Do not put private cloud-STT API keys in the client.
- For this browser implementation, Godot's `AudioStreamMicrophone` is generally unnecessary because the browser API handles microphone capture.

## References
- Godot JavaScriptBridge documentation: https://docs.godotengine.org/en/4.7/tutorials/platform/web/javascript_bridge.html
- Godot custom HTML shell: https://docs.godotengine.org/en/latest/tutorials/platform/web/customizing_html5_shell.html
- MDN SpeechRecognition: https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition
