// Basic tests to verify the project builds correctly and core utilities work.
// For production, add comprehensive widget tests, golden tests, and unit tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footballtraining/utils/responsive_utils.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/widgets/adaptive_scaffold_wrapper.dart';

void main() {
  group('Basic Component Tests', () {
    testWidgets('ResponsiveUtils methods work correctly', (WidgetTester tester) async {
      // Create a test widget to provide context
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test responsive utilities - these should not throw
              ResponsiveUtils.isMobile(context);
              ResponsiveUtils.isTablet(context);
              ResponsiveUtils.isDesktop(context);
              ResponsiveUtils.getScreenSize(context);
              ResponsiveUtils.getGridColumns(context);
              ResponsiveUtils.getMaxContentWidth(context);
              
              // Test methods with parameters
              ResponsiveUtils.getPadding(context);
              ResponsiveUtils.getSpacing(context);
              ResponsiveUtils.getWidthPercentage(context);
              
              return const Scaffold(
                body: Center(child: Text('Test')),
              );
            },
          ),
        ),
      );

      // Verify the widget builds without errors
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('AdaptiveScaffoldWrapper renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdaptiveScaffoldWrapper(
            body: Text('Adaptive Content'),
          ),
        ),
      );

      expect(find.text('Adaptive Content'), findsOneWidget);
    });

    test('OrganizationContextException creates correctly', () {
      const exception = OrganizationContextException('Test message');
      expect(exception.message, equals('Test message'));
      expect(exception.toString(), contains('Test message'));
    });
  });

  group('Responsive Utils Unit Tests', () {
    test('ResponsiveUtils static methods work', () {
      // Test breakpoint constants exist (indirectly through getGridColumns logic)
      expect(ResponsiveUtils.getGridColumns, isA<Function>());
      expect(ResponsiveUtils.getMaxContentWidth, isA<Function>());
    });
  });

  group('Widget Integration Tests', () {
    testWidgets('Basic responsive widget functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Test that responsive layout doesn't crash
                return ResponsiveUtils.responsiveLayout(
                  context,
                  mobile: const Text('Any Layout'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Any Layout'), findsOneWidget);
    });

    testWidgets('AdaptiveScaffoldWrapper with all parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveScaffoldWrapper(
            appBar: AppBar(title: const Text('Test App')),
            body: const Center(child: Text('Main Content')),
            maxContentWidth: 800,
            padding: const EdgeInsets.all(16),
          ),
        ),
      );

      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Main Content'), findsOneWidget);
    });
  });
}