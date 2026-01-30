class SavedQrRecord {
  const SavedQrRecord({
    required this.id,
    required this.title,
    required this.payload,
    required this.category,
    required this.createdAt,
    required this.imagePath,
    this.userEmail,
  });

  final String id;
  final String title;
  final String payload;
  final String category;
  final DateTime createdAt;
  final String imagePath;
  final String? userEmail;
}
