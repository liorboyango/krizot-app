import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/models/station.dart';
import 'package:krizot_app/utils/app_colors.dart';
import 'package:krizot_app/widgets/status_chip.dart';

void main() {
  Widget buildChip(StatusChip chip) {
    return MaterialApp(
      home: Scaffold(body: Center(child: chip)),
    );
  }

  testWidgets('active station chip shows Active label', (tester) async {
    await tester.pumpWidget(
      buildChip(StatusChip.fromStationStatus(StationStatus.active)),
    );
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('closed station chip shows Closed label', (tester) async {
    await tester.pumpWidget(
      buildChip(StatusChip.fromStationStatus(StationStatus.closed)),
    );
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('covered chip shows Covered label', (tester) async {
    await tester.pumpWidget(buildChip(StatusChip.covered()));
    expect(find.text('Covered'), findsOneWidget);
  });

  testWidgets('open chip shows Open label', (tester) async {
    await tester.pumpWidget(buildChip(StatusChip.open()));
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('critical chip shows Critical label', (tester) async {
    await tester.pumpWidget(buildChip(StatusChip.critical()));
    expect(find.text('Critical'), findsOneWidget);
  });

  testWidgets('active chip has green background', (tester) async {
    await tester.pumpWidget(
      buildChip(StatusChip.fromStationStatus(StationStatus.active)),
    );
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(StatusChip),
        matching: find.byType(Container),
      ).first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.shiftCovered);
  });
}
