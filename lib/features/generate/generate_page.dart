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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('QR türünü seç ve ilgili formu doldur.'),
        const SizedBox(height: 16),
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
            return Card(
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
                      Icon(category.icon, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        category.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (isLocked) ...[
                        const SizedBox(height: 6),
                        Icon(
                          Icons.lock,
                          size: 18,
                          color: Theme.of(context).colorScheme.secondary,
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
    );
  }
}
