import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

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
    );
  }
}
