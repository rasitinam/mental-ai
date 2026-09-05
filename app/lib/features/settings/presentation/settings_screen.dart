import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/local_prefs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Sunucu adresi'),
            subtitle: Text(AppConstants.apiBaseUrl),
          ),
          ListTile(
            title: const Text('Cihaz kimliği'),
            subtitle: Text(userId),
          ),
          const Divider(),
          const ListTile(
            title: Text('Gizlilik'),
            subtitle: Text(
              'Verilerin yalnızca kendi bilgisayarındaki yerel veritabanında saklanır.',
            ),
          ),
          const ListTile(
            title: Text('Yasal uyarı'),
            subtitle: Text(
              'Mental AI lisanslı bir sağlık uzmanının yerini tutmaz. '
              'Acil bir durumdaysan 112\'yi ara.',
            ),
          ),
        ],
      ),
    );
  }
}
