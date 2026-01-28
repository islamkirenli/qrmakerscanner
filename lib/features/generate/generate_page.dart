import 'package:flutter/material.dart';
import '../../app/controller_scope.dart';
import 'generate_category.dart';
import 'generate_detail_page.dart';

class GeneratePage extends StatefulWidget {
  const GeneratePage({super.key});

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  void _openCategory(GenerateCategoryInfo category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GenerateDetailPage(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = QrControllerScope.of(context);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            itemCount: generateCategories.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final category = generateCategories[index];
            final isLocked = !controller.isSignedIn &&
                (category.type == GenerateCategoryType.document ||
                    category.type == GenerateCategoryType.image);
            final theme = Theme.of(context);
            return Card(
              color: theme.colorScheme.primary,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bu kategori için giriş yapmalısın.'),
                        ),
                      );
                      return;
                    }
                    _openCategory(category);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        size: 36,
                        color: theme.colorScheme.surface,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.surface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isLocked) ...[
                        const SizedBox(height: 6),
                        Icon(
                          Icons.lock,
                          size: 18,
                          color: theme.colorScheme.surface,
                        ),
                      ],
                    ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
