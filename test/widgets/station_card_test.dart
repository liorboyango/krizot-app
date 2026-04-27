import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krizot_app/models/station.dart';
import 'package:krizot_app/widgets/station_card.dart';

void main() {
  final testStation = Station(
    id: 'abc123def456',
    name: 'Alpha Station',
    location: 'North Sector',
    capacity: 4,
    status: StationStatus.active,
    notes: 'Main entry point',
    scheduleCount: 2,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget buildCard({
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StationCard(
          station: testStation,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }

  testWidgets('displays station name', (tester) async {
    await tester.pumpWidget(buildCard());
    expect(find.text('Alpha Station'), findsOneWidget);
  });

  testWidgets('displays station location', (tester) async {
    await tester.pumpWidget(buildCard());
    expect(find.text('North Sector'), findsOneWidget);
  });

  testWidgets('displays capacity', (tester) async {
    await tester.pumpWidget(buildCard());
    expect(find.text('4 slots'), findsOneWidget);
  });

  testWidgets('displays Active status chip', (tester) async {
    await tester.pumpWidget(buildCard());
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('shows edit button when onEdit provided', (tester) async {
    bool editCalled = false;
    await tester.pumpWidget(buildCard(onEdit: () => editCalled = true));
    await tester.tap(find.text('Edit'));
    expect(editCalled, isTrue);
  });

  testWidgets('shows delete button when onDelete provided', (tester) async {
    bool deleteCalled = false;
    await tester.pumpWidget(buildCard(onDelete: () => deleteCalled = true));
    await tester.tap(find.text('Delete'));
    expect(deleteCalled, isTrue);
  });

  testWidgets('displays notes when present', (tester) async {
    await tester.pumpWidget(buildCard());
    expect(find.text('Main entry point'), findsOneWidget);
  });

  testWidgets('displays station ID badge', (tester) async {
    await tester.pumpWidget(buildCard());
    // ID is first 6 chars of 'abc123def456' = 'ABC123'
    expect(find.text('ST-ABC123'), findsOneWidget);
  });
}
