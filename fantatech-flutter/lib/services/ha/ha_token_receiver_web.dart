// מקבל HA token מה-iframe parent דרך postMessage (Flutter Web בלבד)
// HA → panelJS.postMessage({type:'ha_auth', token, hassUrl}) → Flutter

import 'dart:async';
import 'dart:js_interop';

// Minimal JS interop types needed for postMessage
@JS('window')
external _Window get _window;

@JS()
@staticInterop
class _Window {}

extension _WindowExt on _Window {
  @JS('parent')
  external _Window get parent;

  @JS('addEventListener')
  external void addEventListener(String type, JSFunction listener);

  @JS('postMessage')
  external void postMessage(JSAny message, String targetOrigin);
}

@JS()
@anonymous
@staticInterop
class _MessageEvent {}

extension _MessageEventExt on _MessageEvent {
  @JS('data')
  external JSAny? get data;
}

class HaTokenReceiver {
  static final _ctrl = StreamController<Map<String, String>>.broadcast();

  static Stream<Map<String, String>> get onToken => _ctrl.stream;

  static void init() {
    try {
      _window.parent.postMessage(
        {'type': 'request_ha_token'}.jsify()!,
        '*',
      );
    } catch (_) {}

    _window.addEventListener(
      'message',
      ((JSAny event) {
        try {
          final e    = event as _MessageEvent;
          final data = e.data?.dartify() as Map?;
          if (data == null) return;
          if (data['type'] != 'ha_auth') return;
          final token   = data['token']   as String?;
          final hassUrl = data['hassUrl'] as String?;
          if (token != null && hassUrl != null) {
            _ctrl.add({'token': token, 'hassUrl': hassUrl});
          }
        } catch (_) {}
      }).toJS,
    );
  }

  static void dispose() => _ctrl.close();
}
