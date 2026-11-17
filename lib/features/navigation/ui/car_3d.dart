import 'dart:async';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Visor glTF transparente con la moto 3D (se monta una vez y se oculta con opacidad).
class Car3D extends StatefulWidget {
  const Car3D({super.key, required this.onReady, required this.yawDeg});

  final VoidCallback onReady;
  final double yawDeg;

  @override
  State<Car3D> createState() => Car3DState();
}

class Car3DState extends State<Car3D> {
  WebViewController? _web;
  bool _ready = false;
  double _lastYaw = 999;

  @override
  void didUpdateWidget(Car3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready && (widget.yawDeg - _lastYaw).abs() > 1.2) {
      _lastYaw = widget.yawDeg;
      _web?.runJavaScript(
          "document.querySelector('#moto').orientation='0deg 0deg ${widget.yawDeg.toStringAsFixed(1)}deg';");
    }
  }

  Future<void> _poll() async {
    for (var i = 0; i < 50 && !_ready && mounted; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      try {
        final r = await _web?.runJavaScriptReturningResult(
            "document.querySelector('#moto').loaded");
        if ('$r' == 'true' || '$r' == '1') {
          _ready = true;
          widget.onReady();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          width: 104,
          height: 130,
          child: ModelViewer(
            id: 'moto',
            src: 'assets/models/moto.glb',
            backgroundColor: Colors.transparent,
            cameraControls: false,
            disableZoom: true,
            disablePan: true,
            disableTap: true,
            interactionPrompt: InteractionPrompt.none,
            cameraOrbit: '0deg 52deg auto',
            fieldOfView: '28deg',
            environmentImage: 'neutral',
            exposure: 1.05,
            relatedCss:
                'model-viewer::part(default-progress-bar){display:none}',
            loading: Loading.eager,
            reveal: Reveal.auto,
            onWebViewCreated: (c) {
              _web = c;
              _poll();
            },
          ),
        ),
      ),
    );
  }
}
