import 'package:flutter/material.dart';

import 'panel/dashboard_views.dart';

void main() => runApp(const PanelPreview());

class PanelPreview extends StatelessWidget {
  const PanelPreview({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'InProject · Vista previa',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: panelNavy),
      useMaterial3: true,
    ),
    home: const _PreviewHome(),
  );
}

class _PreviewHome extends StatefulWidget {
  const _PreviewHome();
  @override
  State<_PreviewHome> createState() => _PreviewHomeState();
}

class _PreviewHomeState extends State<_PreviewHome> {
  int _index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('InProject'),
      backgroundColor: panelNavy,
      foregroundColor: Colors.white,
    ),
    body: Column(
      children: [
        const ColoredBox(
          color: Color(0xFFFFF1CB),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'Vista previa · Sin sesión ni conexión a Firebase',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Expanded(
          child: DashboardSection(
            index: _index,
            userName: 'Sergio',
            onNavigate: (index) => setState(() => _index = index),
          ),
        ),
      ],
    ),
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _index,
      selectedItemColor: panelNavy,
      unselectedItemColor: Colors.blueGrey,
      onTap: (index) => setState(() => _index = index),
      items: panelDestinations,
    ),
  );
}
