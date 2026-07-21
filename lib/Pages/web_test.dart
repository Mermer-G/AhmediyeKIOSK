import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewTestPage extends StatefulWidget {
  const WebViewTestPage({super.key});

  @override
  State<WebViewTestPage> createState() => _WebViewTestPageState();
}

class _WebViewTestPageState extends State<WebViewTestPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse("https://www.google.com"),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WebView Test"),
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}