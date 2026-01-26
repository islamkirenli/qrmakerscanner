import 'package:flutter/material.dart';
import '../../app/controller_scope.dart';
import '../../models/qr_record.dart';
import '../../widgets/empty_state.dart';
import '../account/account_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = QrControllerScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.isSignedIn) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Geçmişi görmek için giriş yapmalısın.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AccountPage(),
                      ),
                    ),
                    child: const Text('Giriş Yap'),
                  ),
                ],
              ),
            ),
          );
        }
        final history = controller.history;
        if (history.isEmpty) {
          return const EmptyState(
            title: 'Geçmiş boş',
            subtitle: 'Taradıkların ve oluşturdukların burada listelenecek.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final record = history[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  record.type == QrEntryType.scan
                      ? Icons.qr_code_scanner
                      : Icons.qr_code_2,
                ),
                title: Text(record.payload),
                subtitle: Text(_formatDate(record.createdAt)),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} $hour:$minute';
  }
}
