import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/controller_scope.dart';
import '../../models/saved_qr_record.dart';
import '../../state/qr_app_controller.dart';
import '../../widgets/empty_state.dart';
import '../account/account_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Future<void> _handleDelete(QrAppController controller) async {
    final result = await controller.deleteSelected();
    if (!mounted) {
      return;
    }
    if (!result.ok) {
      final message = result.message ?? 'Silme işlemi başarısız.';
      debugPrint('Delete selected failed: $message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seçili QR kodları silindi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = QrControllerScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final header = _buildHeader(controller);
        if (!controller.isSignedIn) {
          return Center(
            child: Column(
              children: [
                header,
                Expanded(
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
                ),
              ],
            ),
          );
        }
        final history = controller.savedHistory;
        final hasError = controller.historyError != null;
        if (hasError && history.isEmpty) {
          return Column(
            children: [
              header,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.historyError!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: controller.retryHistory,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        if (controller.isHistoryLoading && history.isEmpty) {
          return Column(
            children: [
              header,
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          );
        }
        if (history.isEmpty) {
          return Column(
            children: [
              header,
              const Expanded(
                child: EmptyState(
                  title: 'Geçmiş boş',
                  subtitle: 'Kaydettiğin QR kodlar burada listelenecek.',
                ),
              ),
            ],
          );
        }
        final showErrorBanner = hasError && history.isNotEmpty;
        return Column(
          children: [
            header,
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: history.length + (showErrorBanner ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (showErrorBanner && index == 0) {
                    return Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(
                        title: Text(
                          controller.historyError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: controller.retryHistory,
                          child: const Text('Tekrar Dene'),
                        ),
                      ),
                    );
                  }
                  final record = history[showErrorBanner ? index - 1 : index];
                  final isSelected = controller.isSelected(record.id);
                  return Card(
                    color: const Color(0xFF6A704C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? const BorderSide(color: Color(0xFFF1E6D9), width: 2)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.qr_code_2,
                        color: Color(0xFFF1E6D9),
                      ),
                      title: Text(
                        record.title,
                        style: const TextStyle(color: Color(0xFFF1E6D9)),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (record.category.isNotEmpty)
                            Text(
                              record.category,
                              style: const TextStyle(color: Color(0xFFF1E6D9)),
                            ),
                          Text(
                            record.payload,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFF1E6D9)),
                          ),
                          Text(
                            _formatDate(record.createdAt),
                            style: const TextStyle(color: Color(0xFFF1E6D9)),
                          ),
                        ],
                      ),
                      trailing: controller.isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (_) => controller.toggleSelection(record.id),
                              checkColor: const Color(0xFF6A704C),
                              activeColor: const Color(0xFFF1E6D9),
                            )
                          : null,
                      onTap: controller.isSelectionMode
                          ? () => controller.toggleSelection(record.id)
                          : () => _showQrDialog(context, record),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(QrAppController controller) {
    if (!controller.isSelectionMode) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            '${controller.selectedCount} seçili',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          TextButton(
            onPressed:
                controller.isDeleting ? null : controller.toggleSelectionMode,
            child: const Text('İptal'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed:
                controller.isDeleting ? null : () => _handleDelete(controller),
            child: controller.isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} $hour:$minute';
  }

  void _showQrDialog(BuildContext context, SavedQrRecord record) {
    showDialog<void>(
      context: context,
      builder: (context) => _HistoryQrDialog(record: record),
    );
  }
}

class _HistoryQrDialog extends StatefulWidget {
  const _HistoryQrDialog({required this.record});

  final SavedQrRecord record;

  @override
  State<_HistoryQrDialog> createState() => _HistoryQrDialogState();
}

class _HistoryQrDialogState extends State<_HistoryQrDialog> {
  @override
  Widget build(BuildContext context) {
    final payload = widget.record.payload;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.record.title,
              key: const ValueKey('historyQrTitle'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            QrImageView(
              key: const ValueKey('historyQrPreview'),
              data: payload,
              size: 220,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('historyQrDownloadButton'),
              onPressed: () => debugPrint('İndirildi'),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF6A704C),
                foregroundColor: const Color(0xFFF1E6D9),
                side: BorderSide.none,
              ),
              icon: const Icon(Icons.download),
              label: const Text('İndir'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }
}
