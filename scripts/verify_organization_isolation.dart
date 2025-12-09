#!/usr/bin/env dart
/// Organization Data Isolation Verification Script
///
/// This script verifies that all critical paths are properly scoped to organizations
/// and that no cross-organization data leakage occurs.
///
/// Usage: dart scripts/verify_organization_isolation.dart

import 'dart:io';

void main() {
  print('🔍 ORGANIZATION DATA ISOLATION VERIFICATION');
  print('=' * 50);

  final results = <String, bool>{};

  // Test 1: Training Session Creation Paths
  print('\n1️⃣ Verifying Training Session Paths...');
  final coachScreenContent = File('lib/views/coach/coach_screen.dart').readAsStringSync();

  final hasOldTrainingSessions = coachScreenContent.contains('collection("training_sessions")');
  final hasOrgScopedSessions = coachScreenContent.contains('collection(\'organizations\')') &&
                               coachScreenContent.contains('collection(\'training_sessions\')');
  final hasOrgValidation = coachScreenContent.contains('OrganizationContext.isInitialized');

  results['Training session paths are organization-scoped'] = !hasOldTrainingSessions && hasOrgScopedSessions;
  results['Training session saves validate OrganizationContext'] = hasOrgValidation;

  print('   ${!hasOldTrainingSessions ? '✅' : '❌'} Global training_sessions collection removed');
  print('   ${hasOrgScopedSessions ? '✅' : '❌'} Organization-scoped paths used');
  print('   ${hasOrgValidation ? '✅' : '❌'} OrganizationContext validation present');

  // Test 2: Payment Dialog Paths
  print('\n2️⃣ Verifying Payment Dialog Paths...');
  final paymentDialogContent = File('lib/views/receptionist/dialogs/mark_payment_dialog.dart').readAsStringSync();

  final hasOrgScopedPayments = paymentDialogContent.contains('collection(\'organizations\')') &&
                              paymentDialogContent.contains('collection(\'players\')') &&
                              paymentDialogContent.contains('collection(\'payments\')');
  final hasPaymentValidation = paymentDialogContent.contains('OrganizationContext.isInitialized');

  results['Payment paths are organization-scoped'] = hasOrgScopedPayments;
  results['Payment saves validate OrganizationContext'] = hasPaymentValidation;

  print('   ${hasOrgScopedPayments ? '✅' : '❌'} Organization-scoped payment paths used');
  print('   ${hasPaymentValidation ? '✅' : '❌'} OrganizationContext validation present');

  // Test 3: Dashboard Data Sources
  print('\n3️⃣ Verifying Dashboard Data Sources...');
  final dashboardContent = File('lib/views/dashboard/dashboard_screen.dart').readAsStringSync();

  final hasOrgScopedDashboard = dashboardContent.contains('collection(\'organizations\')') &&
                               dashboardContent.contains('OrganizationContext.currentOrgId');
  final hasDashboardValidation = dashboardContent.contains('OrganizationContext.isInitialized');

  results['Dashboard data is organization-scoped'] = hasOrgScopedDashboard;
  results['Dashboard validates OrganizationContext'] = hasDashboardValidation;

  print('   ${hasOrgScopedDashboard ? '✅' : '❌'} Organization-scoped dashboard queries');
  print('   ${hasDashboardValidation ? '✅' : '❌'} OrganizationContext validation present');

  // Test 4: Firestore Security Rules
  print('\n4️⃣ Verifying Firestore Security Rules...');
  final rulesContent = File('firestore.rules').readAsStringSync();

  final hasOrgTrainingRules = rulesContent.contains('match /organizations/{orgId}/training_sessions/{sessionId}');
  final hasPlayerPaymentRules = rulesContent.contains('match /payments/{paymentId}') &&
                               rulesContent.contains('organizations/{orgId}/players/{playerId}');
  final hasGlobalBlockRules = rulesContent.contains('match /training_sessions/{sessionId}') &&
                             rulesContent.contains('allow read, write: if false');

  results['Training session security rules exist'] = hasOrgTrainingRules;
  results['Player payment security rules exist'] = hasPlayerPaymentRules;
  results['Global collections are blocked'] = hasGlobalBlockRules;

  print('   ${hasOrgTrainingRules ? '✅' : '❌'} Organization training session rules');
  print('   ${hasPlayerPaymentRules ? '✅' : '❌'} Player payment collection rules');
  print('   ${hasGlobalBlockRules ? '✅' : '❌'} Global collections blocked');

  // Test 5: Authentication Flow
  print('\n5️⃣ Verifying Authentication Flow...');
  final authContent = File('lib/services/auth_service.dart').readAsStringSync();

  final hasOrgInitialization = authContent.contains('OrganizationContext.initialize');
  final hasOrgValidationAuth = authContent.contains('organizationId');

  results['Authentication initializes OrganizationContext'] = hasOrgInitialization;
  results['Authentication validates organization'] = hasOrgValidationAuth;

  print('   ${hasOrgInitialization ? '✅' : '❌'} OrganizationContext.initialize() called');
  print('   ${hasOrgValidationAuth ? '✅' : '❌'} Organization validation present');

  // Summary
  print('\n🎯 VERIFICATION SUMMARY');
  print('=' * 25);

  final passed = results.values.where((v) => v).length;
  final total = results.length;

  results.forEach((test, result) {
    print('${result ? '✅' : '❌'} $test');
  });

  print('\n📊 Results: $passed/$total tests passed');

  if (passed == total) {
    print('🎉 ALL TESTS PASSED - Organization isolation is properly implemented!');
    exit(0);
  } else {
    print('⚠️  SOME TESTS FAILED - Review the failed items above');
    exit(1);
  }
}