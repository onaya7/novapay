import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/server/api_exception.dart';
import 'package:novapay/server/repositories/account_repository.dart';
import 'package:novapay/server/repositories/idempotency_repository.dart';
import 'package:novapay/server/repositories/transaction_repository.dart';
import 'package:novapay/server/services/transfer_service.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late AccountRepository accounts;
  late TransactionRepository transactions;
  late IdempotencyRepository idempotency;
  late TransferService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('novapay_transfer');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('transfer_test');
    final db = LocalDataStorageImpl(box);
    accounts = AccountRepositoryImpl(db);
    transactions = TransactionRepositoryImpl(db);
    idempotency = IdempotencyRepositoryImpl(db);
    service = TransferServiceImpl(accounts, transactions, idempotency);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> send({String key = 'k1', int amountKobo = 500000}) =>
      service.execute(
        idempotencyKey: key,
        recipient: '0123456789',
        amountKobo: amountKobo,
      );

  test('debits the wallet and records the transfer', () async {
    await send();
    expect(accounts.balanceKobo(), 24300000);
    expect(transactions.findAll(), hasLength(1));
    expect(transactions.findAll().single.amountKobo, -500000);
    expect(idempotency.hasSeen('k1'), isTrue);
  });

  test('the same key applied three times moves money once', () async {
    await send();
    await send();
    await send();
    expect(accounts.balanceKobo(), 24300000);
    expect(transactions.findAll(), hasLength(1));
  });

  test('different keys are different transfers', () async {
    await send();
    await send(key: 'k2');
    expect(accounts.balanceKobo(), 23800000);
    expect(transactions.findAll(), hasLength(2));
  });

  test('refuses more than the wallet holds, leaving it untouched', () async {
    await expectLater(send(amountKobo: 99900000), throwsA(isA<ApiException>()));
    expect(accounts.balanceKobo(), 24800000);
    expect(idempotency.hasSeen('k1'), isFalse);
    expect(transactions.findAll(), isEmpty);
  });

  test('refuses a zero or negative amount', () async {
    await expectLater(send(amountKobo: 0), throwsA(isA<ApiException>()));
    await expectLater(send(amountKobo: -100), throwsA(isA<ApiException>()));
    expect(accounts.balanceKobo(), 24800000);
  });

  test('spending the whole balance is allowed', () async {
    await send(amountKobo: 24800000);
    expect(accounts.balanceKobo(), 0);
  });

  test('a refusal message is written for the customer', () {
    expect(
      const ApiException('Not enough in your wallet').message,
      'Not enough in your wallet',
    );
    expect(const ApiException('nope').toString(), contains('nope'));
  });
}
