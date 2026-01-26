import 'package:flutter/material.dart';

enum GenerateCategoryType {
  text,
  url,
  email,
  vcard,
  wifi,
  social,
  document,
  image,
  apps,
}

class GenerateCategoryInfo {
  const GenerateCategoryInfo({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final GenerateCategoryType type;
  final String title;
  final String subtitle;
  final IconData icon;
}

const List<GenerateCategoryInfo> generateCategories = [
  GenerateCategoryInfo(
    type: GenerateCategoryType.text,
    title: 'Metin',
    subtitle: 'Düz metin veya notlar için QR.',
    icon: Icons.notes,
  ),
  GenerateCategoryInfo(
    type: GenerateCategoryType.url,
    title: 'URL',
    subtitle: 'Web bağlantıları için QR.',
    icon: Icons.link,
  ),
  GenerateCategoryInfo(
    type: GenerateCategoryType.email,
    title: 'Email',
    subtitle: 'Mail gönderimi için QR.',
    icon: Icons.email,
  ),
  GenerateCategoryInfo(
    type: GenerateCategoryType.vcard,
    title: 'vCard',
    subtitle: 'Kişi kartı paylaşımı için QR.',
    icon: Icons.contact_page,
  ),
  GenerateCategoryInfo(
    type: GenerateCategoryType.wifi,
    title: 'Wi-Fi',
    subtitle: 'Kablosuz ağ paylaşımı için QR.',
    icon: Icons.wifi,
  ),
  GenerateCategoryInfo(
    type: GenerateCategoryType.social,
    title: 'Social Media',
    subtitle: 'Sosyal medya profili için QR.',
    icon: Icons.public,
  ),
  GenerateCategoryInfo(
    type: GenerateCategoryType.document,
    title: 'Document',
    subtitle: 'Belge bağlantısı için QR.',
    icon: Icons.description,
  ),
  GenerateCategoryInfo(
    type: GenerateCategoryType.image,
    title: 'Image',
    subtitle: 'Görsel bağlantısı için QR.',
    icon: Icons.image,
  ),
  GenerateCategoryInfo(
    type: GenerateCategoryType.apps,
    title: 'Apps',
    subtitle: 'Uygulama bağlantısı için QR.',
    icon: Icons.apps,
  ),
];
