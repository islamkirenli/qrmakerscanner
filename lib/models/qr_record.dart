enum QrEntryType { scan, generate }

class QrRecord {
  const QrRecord({
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final QrEntryType type;
  final String payload;
  final DateTime createdAt;
}
