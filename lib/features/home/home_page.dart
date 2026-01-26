import 'package:flutter/material.dart';
import '../../app/controller_scope.dart';
import '../account/account_page.dart';
import '../generate/generate_page.dart';
import '../history/history_page.dart';
import '../scan/scan_page.dart';

class QrHomePage extends StatelessWidget {
  const QrHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = QrControllerScope.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: controller.tabIndexListenable,
      builder: (context, index, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('QR Maker & Scanner'),
          ),
          body: IndexedStack(
            index: index,
            children: const [
              ScanPage(),
              GeneratePage(),
              HistoryPage(),
              AccountPage(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: controller.setTabIndex,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Tara',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_2),
                label: 'Oluştur',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Geçmiş',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}
