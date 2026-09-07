# Remaining Work: Speech-to-Text

## Current status

The project has most of the speech-to-text logic started:

- `speech/speech_manager.gd` exists.
- The browser bridge uses `SpeechRecognition` / `webkitSpeechRecognition`.
- Recognized text is emitted through the `speech_result` signal.
- `player/player.gd` parses `forward`, `back`, `left`, `right`, and `stop` commands.
- The intended target remains a Godot 4.7.2 HTML5 export hosted on GitHub Pages.

The feature is not ready to test end to end yet because the project-level wiring and web validation are incomplete.

## Required work, in order

### 1. Register `SpeechManager` as an autoload

`player/player.gd` calls `SpeechManager.speech_result`, but `project.godot` currently does not contain an autoload entry.

Add the script as an autoload named `SpeechManager`:

```ini
[autoload]

SpeechManager="*res://speech/speech_manager.gd"
```

Use the Godot Project Settings UI if preferred: Project > Project Settings > Globals > Autoload.

### 2. Add the `voice_listen` input action

`player/player.gd` listens for an action named `voice_listen`, but this action is not currently defined in `project.godot`.

Add a push-to-talk key, for example `V`, through Project Settings > Input Map. The action must support both press and release because the player starts recognition on press and stops it on release.

Then verify the generated input entry contains the expected key binding.

### 3. Handle browser errors and availability in the game UI

The manager already emits `speech_error`, `listening_started`, and `listening_stopped`, but gameplay does not connect to them.

Add a small UI status label or debug message that can show:

- Browser speech recognition is unavailable.
- Microphone permission was denied.
- Recognition started.
- Recognition stopped.
- A recognition/network error occurred.

The game should still be playable with keyboard controls when speech recognition is unavailable.

### 4. Make the browser bridge more defensive

Before release, handle these cases:

- `recognition.start()` throws when called while recognition is already active.
- `recognition.stop()` is called after the browser has already stopped.
- The browser sends an `onend` event after an error.
- The user denies microphone permission.
- A browser does not implement `SpeechRecognition` or `webkitSpeechRecognition`.
- The browser requires a user gesture before starting recognition.

Keep this browser-specific behavior inside `SpeechManager`; do not move JavaScript calls into player gameplay code.

### 5. Decide and configure the language

The current bridge uses `en-US`. Confirm whether the commands will be English or Thai.

If Thai commands are required, change the recognition language and update the accepted command phrases. Test accented, capitalized, and punctuation-terminated results after normalization.

### 6. Improve command matching

The current parser only recognizes exact phrases after lowercasing, trimming, and removing periods.

Add the final command vocabulary and consider handling:

- Extra punctuation such as `,`, `!`, and `?`.
- Repeated whitespace.
- Common recognition variants.
- Whether movement should continue until `stop` or only for a fixed duration.

Document the final voice commands for players.

### 7. Export and test the HTML5 build

Create a Web export from the `game-project-ge` project and test the generated build from a secure origin such as GitHub Pages or localhost.

Test at minimum:

1. Open the game in a supported browser.
2. Press the configured voice key.
3. Grant microphone permission.
4. Speak each movement command.
5. Confirm the player moves in the expected direction.
6. Say `stop` and confirm movement stops.
7. Release the voice key and confirm recognition stops.
8. Reload and verify permission/error behavior.
9. Test an unsupported browser and confirm keyboard movement still works.
10. Test the deployed GitHub Pages URL, not only the editor preview.

### 8. Deploy the web build

After local web testing succeeds:

- Export the final HTML5 build.
- Publish the generated files to the GitHub Pages branch or configured Pages directory.
- Open the deployed HTTPS URL.
- Re-test microphone permission and all commands on the deployed URL.

Do not place cloud STT credentials in the exported client files.

## Definition of done

Speech-to-text is complete when:

- `SpeechManager` is registered and initializes without errors.
- The `voice_listen` action is configured and starts/stops recognition.
- A supported browser returns transcripts to Godot.
- Voice commands move and stop the player correctly.
- Errors and unsupported browsers are shown without breaking keyboard controls.
- The HTML5 export works from the deployed GitHub Pages HTTPS URL.
- The selected browser and language support are documented.

## Files to review

- `speech/speech_manager.gd` - browser bridge and speech signals
- `player/player.gd` - input action and command interpretation
- `project.godot` - autoload and input configuration
- `player/player.tscn` - player scene using `player.gd`
- `aiii/handover(1).md` - original implementation handover
- `aiii/speech_to_text_godot_github_pages.md` - architecture notes
