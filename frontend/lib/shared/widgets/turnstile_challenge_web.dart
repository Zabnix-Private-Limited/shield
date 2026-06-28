import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class TurnstileChallenge extends StatefulWidget {
  final String siteKey;
  final ValueChanged<String?> onTokenChanged;
  final ValueChanged<String>? onError;

  const TurnstileChallenge({
    super.key,
    required this.siteKey,
    required this.onTokenChanged,
    this.onError,
  });

  @override
  State<TurnstileChallenge> createState() => _TurnstileChallengeState();
}

class _TurnstileChallengeState extends State<TurnstileChallenge> {
  late final String _viewType;
  late final String _containerId;
  late final String _tokenCallbackName;
  late final String _expiredCallbackName;
  late final String _errorCallbackName;
  late final JSFunction _tokenCallback;
  late final JSFunction _expiredCallback;
  late final JSFunction _errorCallback;
  String? _widgetId;
  bool _renderRequested = false;

  @override
  void initState() {
    super.initState();
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    _viewType = 'shield-turnstile-view-$suffix';
    _containerId = 'shield-turnstile-container-$suffix';
    _tokenCallbackName = 'shieldTurnstileTokenCallback$suffix';
    _expiredCallbackName = 'shieldTurnstileExpiredCallback$suffix';
    _errorCallbackName = 'shieldTurnstileErrorCallback$suffix';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      return web.HTMLDivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.minHeight = '70px';
    });

    _tokenCallback = ((String token) {
      widget.onTokenChanged(token);
    }).toJS;
    _expiredCallback = (() {
      widget.onTokenChanged(null);
    }).toJS;
    _errorCallback = (() {
      widget.onTokenChanged(null);
      widget.onError?.call('Verification could not be completed.');
    }).toJS;

    globalContext.setProperty(_tokenCallbackName.toJS, _tokenCallback);
    globalContext.setProperty(_expiredCallbackName.toJS, _expiredCallback);
    globalContext.setProperty(_errorCallbackName.toJS, _errorCallback);

    WidgetsBinding.instance.addPostFrameCallback((_) => _renderWhenReady());
  }

  void _renderWhenReady([int attempt = 0]) {
    if (!mounted || _renderRequested) {
      return;
    }

    final host = globalContext.getProperty('shieldTurnstile'.toJS);
    if (host.isUndefinedOrNull) {
      if (attempt >= 20) {
        widget.onError?.call('Turnstile did not load on this page.');
        return;
      }
      Timer(
        const Duration(milliseconds: 250),
        () => _renderWhenReady(attempt + 1),
      );
      return;
    }

    _renderRequested = true;
    final widgetId = (host as JSObject).callMethodVarArgs('render'.toJS, [
      _containerId.toJS,
      widget.siteKey.toJS,
      _tokenCallbackName.toJS,
      _expiredCallbackName.toJS,
      _errorCallbackName.toJS,
    ]);
    _widgetId = widgetId?.dartify()?.toString();
  }

  @override
  void dispose() {
    globalContext.setProperty(_tokenCallbackName.toJS, null);
    globalContext.setProperty(_expiredCallbackName.toJS, null);
    globalContext.setProperty(_errorCallbackName.toJS, null);

    final host = globalContext.getProperty('shieldTurnstile'.toJS);
    if (!host.isUndefinedOrNull && _widgetId != null) {
      (host as JSObject).callMethodVarArgs('remove'.toJS, [_widgetId!.toJS]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
