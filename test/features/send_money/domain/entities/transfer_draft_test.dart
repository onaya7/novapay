import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/money/money.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_draft.dart';
import 'package:novapay/features/send_money/domain/entities/transfer_receipt.dart';

const _available = Money.fromKobo(2000000);

TransferDraft _draft({
  SendStep step = SendStep.recipient,
  String recipient = '0123456789',
  int amountKobo = 500000,
}) => TransferDraft(
  step: step,
  recipient: recipient,
  amount: Money.fromKobo(amountKobo),
  available: _available,
);

void main() {
  group('TransferDraft', () {
    test('a fresh draft has nothing and goes nowhere', () {
      const draft = TransferDraft();

      expect(draft.step, SendStep.recipient);
      expect(draft.recipientIsValid, isFalse);
      expect(draft.amountIsEntered, isFalse);
      expect(draft.canAdvance, isFalse);
      expect(draft.previousStep, isNull);
      expect(draft.nextStep, SendStep.amount);
    });

    test('a recipient must be a ten-digit account number', () {
      expect(_draft(recipient: '012345678').recipientIsValid, isFalse);
      expect(_draft(recipient: '01234567890').recipientIsValid, isFalse);
      expect(_draft(recipient: '012345678a').recipientIsValid, isFalse);
      expect(_draft().recipientIsValid, isTrue);
    });

    test('zero is not an amount', () {
      expect(_draft(amountKobo: 0).amountIsEntered, isFalse);
      expect(_draft(amountKobo: 1).amountIsEntered, isTrue);
    });

    test('enough is measured against available, and the edge is allowed', () {
      expect(_draft(amountKobo: 1999999).hasEnough, isTrue);
      expect(_draft(amountKobo: 2000000).hasEnough, isTrue);
      expect(_draft(amountKobo: 2000001).hasEnough, isFalse);
    });

    test('remaining is what would be left', () {
      expect(_draft().remaining, const Money.fromKobo(1500000));
    });

    test('each step gates on its own field', () {
      expect(_draft(recipient: 'bad').canAdvance, isFalse);
      expect(_draft().canAdvance, isTrue);

      expect(_draft(step: SendStep.amount, amountKobo: 0).canAdvance, isFalse);
      expect(_draft(step: SendStep.amount).canAdvance, isTrue);
    });

    test('the amount step advances even when there is not enough', () {
      final draft = _draft(step: SendStep.amount, amountKobo: 9999999);

      expect(draft.hasEnough, isFalse);
      expect(draft.canAdvance, isTrue);
    });

    test('confirm refuses to submit more than is available', () {
      expect(
        _draft(step: SendStep.confirm, amountKobo: 9999999).canAdvance,
        isFalse,
      );
      expect(_draft(step: SendStep.confirm).canAdvance, isTrue);
    });

    test('the steps walk both ways and stop at each end', () {
      expect(_draft().previousStep, isNull);
      expect(_draft().nextStep, SendStep.amount);

      expect(_draft(step: SendStep.amount).previousStep, SendStep.recipient);
      expect(_draft(step: SendStep.amount).nextStep, SendStep.confirm);

      expect(_draft(step: SendStep.confirm).previousStep, SendStep.amount);
      expect(_draft(step: SendStep.confirm).nextStep, isNull);
    });
  });

  group('TransferReceipt', () {
    test('unsettled is pending, because the app cannot know', () {
      const receipt = TransferReceipt(
        reference: 'r1',
        recipient: '0123456789',
        amount: Money.fromKobo(500000),
        settled: false,
      );

      expect(receipt.isPending, isTrue);
    });

    test('settled is not pending', () {
      const receipt = TransferReceipt(
        reference: 'r1',
        recipient: '0123456789',
        amount: Money.fromKobo(500000),
        settled: true,
      );

      expect(receipt.isPending, isFalse);
    });
  });
}
