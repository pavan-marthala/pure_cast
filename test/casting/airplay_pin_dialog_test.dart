import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/presentation/ui/airplay_pin_dialog.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_buitton.dart';

/// Pumps a host that opens the dialog and records the returned PIN.
Future<void> _pumpHost(
  WidgetTester tester,
  void Function(String?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await showAirPlayPinDialog(
                  context,
                  deviceName: 'Living room TV',
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the prompt names the device and disables Connect until 4 digits', (
    tester,
  ) async {
    await _pumpHost(tester, (_) {});

    expect(find.text('AirPlay pairing'), findsOneWidget);
    expect(
      find.text('Enter the 4-digit code shown on Living room TV.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();
    final connect = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Connect'),
    );
    expect(connect.onPressed, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('a complete PIN is returned to the caller', (tester) async {
    String? result;
    await _pumpHost(tester, (pin) => result = pin);

    await tester.enterText(find.byType(TextField), '4821');
    await tester.pump();
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(result, '4821');
    expect(find.text('AirPlay pairing'), findsNothing);
  });

  testWidgets('cancelling returns null and closes the prompt', (tester) async {
    String? result = 'unchanged';
    await _pumpHost(tester, (pin) => result = pin);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('AirPlay pairing'), findsNothing);
  });
}
