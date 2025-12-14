import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TestWeb extends StatefulWidget {
  @override
  State<TestWeb> createState() => _TestWebState();
}

class _TestWebState extends State<TestWeb> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://google.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Test Browser")),
      body: WebViewWidget(controller: controller),
    );
  }
}