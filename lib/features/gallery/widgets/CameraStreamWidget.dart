import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CameraStreamPage extends StatefulWidget {
  @override
  _CameraStreamPageState createState() => _CameraStreamPageState();
  final String myurl;
  const CameraStreamPage({Key? key, required this.myurl}) : super(key: key);
  // Le constructeur prend l'URL du flux vidéo comme paramètre

}

class _CameraStreamPageState extends State<CameraStreamPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    
    // Initialisation du contrôleur WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Optionnel : afficher le progrès de chargement
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Page resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.myurl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Stream'),
        backgroundColor: Colors.black,
      ),
      body: WebViewWidget(controller: _controller),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Optionnel : ajouter une action pour le bouton flottant
          _controller.reload();
          // change the title of the app bar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stream reloaded'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Icon(Icons.refresh),
        backgroundColor: const Color.fromARGB(255, 129, 129, 129),

      ),
    );
  }
}