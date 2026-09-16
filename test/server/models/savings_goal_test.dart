import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/server/models/savings_goal.dart';

SavingsGoal goal({int savedKobo = 0, int targetKobo = 10000000}) => SavingsGoal(
  id: 'g1',
  name: 'Rent',
  targetKobo: targetKobo,
  savedKobo: savedKobo,
  targetDate: DateTime.utc(2027),
);

void main() {
  test('a new goal is empty and incomplete', () {
    expect(goal().savedKobo, 0);
    expect(goal().percentComplete, 0);
    expect(goal().isComplete, isFalse);
    expect(goal().remaining, const Money.fromKobo(10000000));
  });

  test('progress is whole percent, computed in integers', () {
    expect(goal(savedKobo: 2500000).percentComplete, 25);
    expect(goal(savedKobo: 3333333).percentComplete, 33);
  });

  test('progress truncates rather than flattering the saver', () {
    // 99.99% must not read as complete.
    expect(goal(savedKobo: 9999999).percentComplete, 99);
    expect(goal(savedKobo: 9999999).isComplete, isFalse);
  });

  test('the bar fraction is one-way and bounded', () {
    expect(goal(savedKobo: 2500000).progressFraction, 0.25);
    expect(goal(savedKobo: 20000000).progressFraction, 1.0);
    expect(goal().progressFraction, 0.0);
  });

  test('meeting or passing the target completes it', () {
    expect(goal(savedKobo: 10000000).isComplete, isTrue);
    expect(goal(savedKobo: 12000000).isComplete, isTrue);
    expect(goal(savedKobo: 12000000).percentComplete, 100);
  });

  test('remaining never goes negative', () {
    expect(goal(savedKobo: 12000000).remaining, Money.zero);
  });

  test('exposes money as exact values', () {
    expect(goal(savedKobo: 2500000).saved.format(), '₦25,000.00');
    expect(goal().target.format(), '₦100,000.00');
  });

  test('copyWith changes only the saved amount', () {
    final topped = goal().copyWith(savedKobo: 500000);
    expect(topped.savedKobo, 500000);
    expect(topped.id, 'g1');
    expect(topped.name, 'Rent');
    expect(topped.targetKobo, 10000000);
    expect(goal().copyWith().savedKobo, 0);
  });

  test('round-trips through json', () {
    final decoded = SavingsGoal.fromJson(
      jsonDecode(jsonEncode(goal(savedKobo: 250000).toJson()))
          as Map<String, dynamic>,
    );
    expect(decoded.id, 'g1');
    expect(decoded.name, 'Rent');
    expect(decoded.targetKobo, 10000000);
    expect(decoded.savedKobo, 250000);
    expect(decoded.targetDate, goal().targetDate);
  });

  test('refuses amounts that are not integers', () {
    expect(
      () => SavingsGoal.fromJson(goal().toJson()..['savedKobo'] = 1.5),
      throwsFormatException,
    );
    expect(
      () => SavingsGoal.fromJson(goal().toJson()..['targetKobo'] = 1.5),
      throwsFormatException,
    );
  });

  test('compares by value across every field', () {
    expect(goal(), goal());
    expect(goal().hashCode, goal().hashCode);
    expect(goal() == goal(savedKobo: 999), isFalse);
  });

  test('describes itself for logs', () {
    expect(goal().toString(), contains('Rent'));
  });
}
