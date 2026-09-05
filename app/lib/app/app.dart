import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/glass.dart';

class MentalAiApp extends ConsumerWidget {
  const MentalAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mental AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
      // Paints the app's one constant canvas behind every route, so
      // glass surfaces always sit on the same backdrop instead of each
      // screen picking its own background color.
      builder: (context, child) => AppBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
