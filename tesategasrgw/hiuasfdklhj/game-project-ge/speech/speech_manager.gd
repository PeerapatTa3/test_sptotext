extends Node

signal speech_result(text: String)
signal speech_error(error: String)
signal listening_started
signal listening_stopped

var is_available := false
var is_listening := false
var _callback: JavaScriptObject

func _ready() -> void:
	if not OS.has_feature("web"):
		return

	_callback = JavaScriptBridge.create_callback(_on_browser_event)
	var window := JavaScriptBridge.get_interface("window")
	window.godotSpeechEvent = _callback
	JavaScriptBridge.eval("""
		(() => {
			if (window.__godotSpeech) {
				return;
			}

			const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
			if (!Recognition) {
				window.__godotSpeech = { available: false };
				return;
			}

			const recognition = new Recognition();
			recognition.lang = "en-US";
			recognition.continuous = false;
			recognition.interimResults = false;

			recognition.onresult = (event) => {
				const result = event.results[event.resultIndex || 0];
				if (result && result[0]) {
					window.godotSpeechEvent("result", result[0].transcript);
				}
			};
			recognition.onerror = (event) => {
				window.godotSpeechEvent("error", event.error || "unknown");
			};
			recognition.onstart = () => window.godotSpeechEvent("started", "");
			recognition.onend = () => window.godotSpeechEvent("stopped", "");

			window.__godotSpeech = {
				available: true,
				start: () => {
					try {
						recognition.start();
					} catch (error) {
						window.godotSpeechEvent("error", error.name || "Unable to start speech recognition");
					}
				},
				stop: () => {
					try {
						recognition.stop();
					} catch (error) {
						window.godotSpeechEvent("error", error.name || "Unable to stop speech recognition");
					}
				}
			};
		})();
	""", true)
	is_available = bool(JavaScriptBridge.eval("Boolean(window.__godotSpeech && window.__godotSpeech.available)", true))
	if not is_available:
		speech_error.emit("Speech recognition is not supported by this browser.")

func start_listening() -> void:
	if not OS.has_feature("web"):
		speech_error.emit("Speech recognition is available in the web export only.")
		return
	if not is_available:
		speech_error.emit("Speech recognition is not supported by this browser.")
		return
	if is_listening:
		return

	JavaScriptBridge.eval("window.__godotSpeech.start()", true)

func stop_listening() -> void:
	if not OS.has_feature("web") or not is_available or not is_listening:
		return

	JavaScriptBridge.eval("window.__godotSpeech.stop()", true)

func _on_browser_event(args: Array) -> void:
	if args.is_empty():
		return

	var event_type := str(args[0])
	var value := ""
	if args.size() > 1:
		value = str(args[1])

	match event_type:
		"result":
			var text := value.strip_edges()
			if not text.is_empty():
				speech_result.emit(text)
		"started":
			is_listening = true
			listening_started.emit()
		"stopped":
			is_listening = false
			listening_stopped.emit()
		"error":
			is_listening = false
			speech_error.emit(value)
