import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/glass.dart';

class MentalAiApp extends StatelessWidget {
  const MentalAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mental AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
      // Paints the app's one constant canvas behind every route, so
      // glass surfaces always sit on the same backdrop instead of each
      // screen picking its own background color.
      builder: (context, child) => AppBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
