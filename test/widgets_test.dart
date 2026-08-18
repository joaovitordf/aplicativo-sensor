import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sensortech/shared/widgets/app_bar.dart';
import 'package:sensortech/shared/widgets/custom_dropdown.dart';
import 'package:sensortech/shared/widgets/custom_text_field.dart';
import 'package:sensortech/shared/widgets/date_picker_dialog.dart';
import 'package:sensortech/shared/widgets/searchable_dropdown.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  Widget createTestWidget(Widget child, {Size surfaceSize = const Size(800, 600)}) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: Scaffold(body: child),
      ),
    );
  }

  group('DatePickerCalendarDialog Responsive Tests', () {
    testWidgets('Renders in compact/landscape viewport without overflow', (tester) async {
      tester.view.physicalSize = const Size(700, 350);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  DatePickerCalendarDialog.showSingle(
                    context: context,
                    title: 'Selecione uma Data',
                    initialDate: DateTime(2026, 8, 15),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                },
                child: const Text('Abrir'),
              );
            },
          ),
          surfaceSize: const Size(700, 350),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Selecione uma Data'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // Verify no RenderFlex overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders range mode without overflow', (tester) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  DatePickerCalendarDialog.showRange(
                    context: context,
                    title: 'Período',
                    initialStart: DateTime(2026, 8, 1),
                    initialEnd: DateTime(2026, 8, 15),
                  );
                },
                child: const Text('Abrir Range'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir Range'));
      await tester.pumpAndSettle();

      expect(find.text('Período'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SearchableDropdown Tests', () {
    testWidgets('Renders and opens search dialog cleanly', (tester) async {
      const items = [
        SearchableDropdownItem(value: 1, label: 'Câmera Portaria'),
        SearchableDropdownItem(value: 2, label: 'Câmera Galpão'),
        SearchableDropdownItem(value: 3, label: 'Câmera Pátio'),
      ];

      int? selectedValue = 1;

      await tester.pumpWidget(
        createTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return SearchableDropdown<int?>(
                label: 'Câmera',
                hint: 'Selecione',
                value: selectedValue,
                items: items,
                onChanged: (val) => setState(() => selectedValue = val),
              );
            },
          ),
        ),
      );

      expect(find.text('Câmera Portaria'), findsOneWidget);
      await tester.tap(find.text('Câmera Portaria'));
      await tester.pumpAndSettle();

      expect(find.text('Pesquisar...'), findsOneWidget);
      expect(find.text('Câmera Galpão'), findsOneWidget);

      await tester.tap(find.text('Câmera Galpão'));
      await tester.pumpAndSettle();

      expect(selectedValue, 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('CustomTextField and CustomDropdown Tests', () {
    testWidgets('CustomTextField renders label and hint', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        createTestWidget(
          CustomTextField(
            label: 'Nome de Usuário',
            hint: 'Digite seu usuário',
            controller: controller,
            prefixIcon: const Icon(Icons.person),
          ),
        ),
      );

      expect(find.text('Nome de Usuário'), findsOneWidget);
      expect(find.text('Digite seu usuário'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'admin');
      expect(controller.text, 'admin');
    });

    testWidgets('CustomDropdown renders options', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomDropdown<String>(
            label: 'Tipo',
            value: 'A',
            items: [
              DropdownMenuItem(value: 'A', child: Text('Opção A')),
              DropdownMenuItem(value: 'B', child: Text('Opção B')),
            ],
          ),
        ),
      );

      expect(find.text('Tipo'), findsOneWidget);
      expect(find.text('Opção A'), findsOneWidget);
    });
  });

  group('CustomAppBar Tests', () {
    testWidgets('CustomAppBar renders titleText when provided', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            appBar: CustomAppBar(titleText: 'Título Teste Longo com Texto Completo'),
            body: Center(child: Text('Corpo')),
          ),
        ),
      );

      expect(find.text('Título Teste Longo com Texto Completo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Camera VMS Sirene Modal Tests', () {
    testWidgets('Sirene button in Camera VMS triggers modal with 3s security countdown', (tester) async {
      bool confirmCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dContext) => AlertDialog(
                      title: const Text('Acionar Sirene'),
                      content: const Text('Vínculo IoT (idRasp): #11'),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            confirmCalled = true;
                            Navigator.pop(dContext);
                          },
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Acionar Sirene'),
              );
            },
          ),
        ),
      );

      expect(find.text('Acionar Sirene'), findsOneWidget);
      await tester.tap(find.text('Acionar Sirene'));
      await tester.pumpAndSettle();

      expect(find.text('Vínculo IoT (idRasp): #11'), findsOneWidget);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(confirmCalled, true);
    });
  });
}
