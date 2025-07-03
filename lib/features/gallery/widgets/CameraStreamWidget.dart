
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CameraStreamWidget extends StatefulWidget {
  final String streamUrl;

  const CameraStreamWidget({Key? key, required this.streamUrl}) : super(key: key);

  @override
  State<CameraStreamWidget> createState() => _CameraStreamWidgetState();
}

class _CameraStreamWidgetState extends State<CameraStreamWidget> {
  late final WebViewController _controller;

  @override
void initState() {
  super.initState();

  final htmlContent = '''
  <!DOCTYPE html>
  <html>
  <head>
    <style>
      body {
        margin: 0;
        background-color: black;
        overflow: hidden;
      }
      img {
        width: 100vw;
        height: 100vh;
        object-fit: cover;
      }
    </style>
  </head>
  <body>
    <img src="${widget.streamUrl}" />
  </body>
  </html>
  ''';

  _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(htmlContent);
}


  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}