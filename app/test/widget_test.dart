import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/main_preview.dart';

void main() {
  testWidgets('El panel permite abrir un rubro, volver y cambiar de sección', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PanelPreview());
    await tester.tap(find.text('Ver proyectos y trabajos'));
    await tester.pumpAndSettle();
    expect(find.text('Proyectos y trabajos'), findsOneWidget);
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Albañilería y obra gruesa'));
    await tester.pumpAndSettle();
    expect(find.text('Rubro técnico'), findsOneWidget);
    expect(
      find.text('Muros, pisos y trabajos de construcción.'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Billetera'));
    await tester.pumpAndSettle();
    expect(find.text('InProject Wallet'), findsOneWidget);
    await tester.tap(find.text('Ayuda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¿Dónde encuentro mi perfil?'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Abre el menú lateral y selecciona Mi Perfil para revisar tus datos.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Las categorías caben en móvil estrecho con texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const PanelPreview());
    await tester.scrollUntilVisible(find.text('Carpintería y melamina'), 200);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
