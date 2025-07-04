import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class STLViewer extends StatefulWidget {
  final String fileUrl;

  const STLViewer({Key? key, required this.fileUrl}) : super(key: key);

  @override
  State<STLViewer> createState() => _STLViewerState();
}

class _STLViewerState extends State<STLViewer> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          await _controller.runJavaScript("loadModel('${widget.fileUrl}');");
          setState(() => _isLoading = false);
        },
      ))
      ..loadFlutterAsset('assets/html/viewer2.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aperçu 3D')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
        ],
      ),
    );
  }
}
