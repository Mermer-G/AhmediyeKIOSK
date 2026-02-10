import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

ScreenSize getScreenSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return ScreenSize.compact;
  if (width < 1024) return ScreenSize.medium;
  return ScreenSize.expanded;
}

bool isCompact(BuildContext context) =>
    getScreenSize(context) == ScreenSize.compact;
