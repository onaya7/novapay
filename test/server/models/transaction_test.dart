import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/server/models/transaction.dart';

Transaction tx({String id = 't1', int amountKobo = -500000}) => Transaction(
  id: id,
  title: 'Transfer to 0123456789',
  amountKobo: amountKobo,
  occurredAt: DateTime.utc(2026, 9, 16, 12),
);

void main() {
  test('money out is a debit, money in is not', () {
    expect(tx().isDebit, isTrue);
    expect(tx(amountKobo: 500000).isDebit, isFalse);
  });

  test('exposes its amount as exact money', () {
    expect(tx().amount, const Money.fromKobo(-500000));
    expect(tx().amount.format(), '-₦5,000.00');
  });

  test('round-trips through json', () {
    final decoded = Transaction.fromJson(
      jsonDecode(jsonEncode(tx().toJson())) as Map<String, dynamic>,
    );
    expect(decoded.id, 't1');
    expect(decoded.title, 'Transfer to 0123456789');
    expect(decoded.amountKobo, -500000);
    expect(decoded.occurredAt, tx().occurredAt);
  });

  test('refuses an amount that is not an integer', () {
    final json = tx().toJson()..['amountKobo'] = -5000.0;
    expect(() => Transaction.fromJson(json), throwsFormatException);
  });

  test('compares by value across every field', () {
    expect(tx(), tx());
    expect(tx().hashCode, tx().hashCode);
    expect(tx(id: 'a') == tx(id: 'b'), isFalse);
    expect(tx() == tx(amountKobo: 999), isFalse);
  });

  test('describes itself for logs', () {
    expect(tx().toString(), contains('t1'));
  });
}
