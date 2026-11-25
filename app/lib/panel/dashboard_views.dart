import 'package:flutter/material.dart';

const panelNavy = Color(0xFF12305B);
const panelOrange = Color(0xFFFFA500);
const panelBackground = Color(0xFFF7F9FC);

const technicalCategories = <({String title, String detail, IconData icon})>[
  (
    title: 'Albañilería y obra gruesa',
    detail: 'Muros, pisos y trabajos de construcción.',
    icon: Icons.foundation_outlined,
  ),
  (
    title: 'Acabados y pintura',
    detail: 'Pintura, revestimientos y acabados de ambientes.',
    icon: Icons.format_paint_outlined,
  ),
  (
    title: 'Instalaciones eléctricas',
    detail: 'Instalación y mantenimiento de sistemas eléctricos.',
    icon: Icons.bolt_outlined,
  ),
  (
    title: 'Instalaciones sanitarias',
    detail: 'Instalación y mantenimiento de agua y desagüe.',
    icon: Icons.water_drop_outlined,
  ),
  (
    title: 'Soldadura y estructuras',
    detail: 'Soldadura, rejas y estructuras metálicas.',
    icon: Icons.engineering_outlined,
  ),
  (
    title: 'Carpintería y melamina',
    detail: 'Muebles, puertas y trabajos de carpintería.',
    icon: Icons.carpenter_outlined,
  ),
];

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.index,
    required this.userName,
    required this.onNavigate,
  });

  final int index;
  final String userName;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: panelBackground,
      child: switch (index) {
        0 => _Home(userName: userName, onNavigate: onNavigate),
        1 => const _PendingSection(
          icon: Icons.work_outline,
          title: 'Proyectos y trabajos',
          message: 'Aquí podrás consultar tus proyectos y trabajos. Este recorrido se habilitará en la siguiente entrega.',
        ),
        2 => const _PendingSection(
          icon: Icons.account_balance_wallet_outlined,
          title: 'InProject Wallet',
          message: 'La billetera aún no está habilitada. Por ahora no se realizan recargas, cobros ni pagos desde la aplicación.',
        ),
        _ => const _Help(),
      },
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.userName, required this.onNavigate});
  final String userName;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hola, $userName',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: panelNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Conectando oportunidades.',
          style: TextStyle(color: Color(0xFF65758D)),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: panelNavy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.work_outline, color: panelOrange, size: 30),
              const SizedBox(height: 12),
              const Text(
                'Tus proyectos, en un solo lugar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Accede a la sección de proyectos y trabajos de InProject.',
                style: TextStyle(color: Color(0xFFDCE6F5), height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: panelOrange,
                  foregroundColor: panelNavy,
                ),
                onPressed: () => onNavigate(1),
                child: const Text('Ver proyectos y trabajos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Rubros técnicos',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: panelNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Explora las especialidades de nuestra comunidad.',
          style: TextStyle(color: Color(0xFF65758D)),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 ? 3 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final category in technicalCategories)
                  SizedBox(
                    width: width,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFD7E0ED)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _CategoryDetail(
                              title: category.title,
                              detail: category.detail,
                              icon: category.icon,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                category.icon,
                                color: const Color(0xFFC77700),
                                size: 30,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                category.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: panelNavy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ver rubro →',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF65758D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => onNavigate(3),
          icon: const Icon(Icons.help_outline),
          label: const Text('¿Necesitas ayuda?'),
        ),
      ],
    );
  }
}

class _CategoryDetail extends StatelessWidget {
  const _CategoryDetail({
    required this.title,
    required this.detail,
    required this.icon,
  });
  final String title;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: panelBackground,
    appBar: AppBar(
      title: const Text('Rubro técnico'),
      backgroundColor: panelNavy,
      foregroundColor: Colors.white,
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(icon, color: const Color(0xFFC77700), size: 64),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            color: panelNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(detail, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 24),
        const Text(
          'La búsqueda de oportunidades y profesionales por rubro estará disponible en una próxima entrega.',
          style: TextStyle(color: Color(0xFF65758D), height: 1.5),
        ),
      ],
    ),
  );
}

class _PendingSection extends StatelessWidget {
  const _PendingSection({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      const SizedBox(height: 40),
      Icon(icon, size: 64, color: const Color(0xFFC77700)),
      const SizedBox(height: 24),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: panelNavy,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF65758D), height: 1.6),
      ),
    ],
  );
}

class _Help extends StatelessWidget {
  const _Help();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text(
        '¿Cómo podemos ayudarte?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: panelNavy,
        ),
      ),
      SizedBox(height: 12),
      Text('Encuentra respuestas sobre la navegación de InProject.'),
      SizedBox(height: 20),
      Card(
        child: ExpansionTile(
          title: Text('¿Dónde encuentro mi perfil?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Abre el menú lateral y selecciona Mi Perfil para revisar tus datos.',
              ),
            ),
          ],
        ),
      ),
      Card(
        child: ExpansionTile(
          title: Text('¿Cómo exploro los rubros técnicos?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'En Inicio, pulsa una categoría para conocer el tipo de trabajos que comprende.',
              ),
            ),
          ],
        ),
      ),
      Card(
        child: ExpansionTile(
          title: Text('¿Puedo realizar pagos?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Los pagos y recargas todavía no están habilitados. La sección Billetera informará cuando puedas utilizarlos.',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

const panelDestinations = [
  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
  BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Proyectos'),
  BottomNavigationBarItem(
    icon: Icon(Icons.account_balance_wallet_outlined),
    label: 'Billetera',
  ),
  BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Ayuda'),
];
