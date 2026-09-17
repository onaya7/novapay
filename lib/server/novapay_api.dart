import 'package:injectable/injectable.dart';
import 'package:novapay/server/api_exception.dart';
import 'package:novapay/server/models/api_response.dart';
import 'package:novapay/server/models/savings_goal.dart';
import 'package:novapay/server/models/transaction.dart';
import 'package:novapay/server/repositories/account_repository.dart';
import 'package:novapay/server/repositories/idempotency_repository.dart';
import 'package:novapay/server/repositories/savings_goal_repository.dart';
import 'package:novapay/server/repositories/transaction_repository.dart';
import 'package:novapay/server/services/funding_service.dart';
import 'package:novapay/server/services/savings_service.dart';
import 'package:novapay/server/services/transfer_service.dart';

/// Everything the app may ask of the NovaPay backend.
///
/// The app depends on this, never on an implementation, so the in-process
/// stand-in can be swapped for a real HTTP client by changing one DI binding.
///
/// Every endpoint answers with an [ApiResponse]: a refusal is a response with
/// a code, and only a transport failure throws.
abstract class NovaPayApi {
  ApiResponse<int> balance();
  ApiResponse<List<Transaction>> transactions();
  ApiResponse<List<SavingsGoal>> goals();
  ApiResponse<SavingsGoal> goal(String id);

  Future<ApiResponse<Transaction>> transfer({
    required String idempotencyKey,
    required String recipient,
    required int amountKobo,
    String? bankName,
  });

  Future<ApiResponse<Transaction>> fund({
    required String idempotencyKey,
    required int amountKobo,
  });

  Future<ApiResponse<SavingsGoal>> contribute({
    required String idempotencyKey,
    required String goalId,
    required int amountKobo,
  });

  Future<ApiResponse<SavingsGoal>> createGoal({
    required String id,
    required String name,
    required int targetKobo,
    required DateTime targetDate,
  });

  Future<ApiResponse<SavingsGoal>> updateGoal({
    required String goalId,
    required String name,
    required int targetKobo,
    required DateTime targetDate,
  });

  Future<ApiResponse<bool>> deleteGoal(String goalId);
}

/// The in-process stand-in, backed by the local database.
///
/// `latency`, `failNext`, `hasApplied` and `reset` are deliberately absent
/// from [NovaPayApi]: they are demo and test affordances, and a real server
/// would not offer them, so app code must not be able to reach them.
@LazySingleton(as: NovaPayApi)
class NovaPayApiImpl implements NovaPayApi {
  NovaPayApiImpl(
    this._transfers,
    this._savings,
    this._funding,
    this._accounts,
    this._transactions,
    this._goals,
    this._idempotency,
  );

  final TransferService _transfers;
  final SavingsService _savings;
  final FundingService _funding;
  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final SavingsGoalRepository _goals;
  final IdempotencyRepository _idempotency;

  /// Simulated round trip, so Pending is visible rather than instant.
  Duration latency = const Duration(milliseconds: 600);

  /// Makes the next [failNext] calls fail at the transport layer.
  int failNext = 0;

  Future<void> _transport() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failNext > 0) {
      failNext--;
      throw const ApiException('The server could not be reached');
    }
  }

  /// Runs an endpoint, turning a refusal into an error response the way a
  /// controller maps a thrown domain error onto a status code.
  Future<ApiResponse<T>> _handle<T>(
    Future<T> Function() endpoint, {
    int successCode = 200,
  }) async {
    await _transport();
    try {
      final data = await endpoint();
      return ApiResponse<T>.ok(data, code: successCode);
    } on ApiException catch (error) {
      return ApiResponse<T>.failure(
        code: _codeFor(error.message),
        message: error.message,
      );
    }
  }

  /// Maps a refusal onto the status code a real API would answer with.
  static int _codeFor(String message) {
    if (message.contains('no longer exists')) return 404;
    if (message.contains('Not enough')) return 402;
    return 422;
  }

  bool hasApplied(String idempotencyKey) =>
      _idempotency.hasSeen(idempotencyKey);

  @override
  ApiResponse<int> balance() => ApiResponse<int>.ok(_accounts.balanceKobo());

  @override
  ApiResponse<List<Transaction>> transactions() =>
      ApiResponse<List<Transaction>>.ok(_transactions.findAll());

  @override
  ApiResponse<List<SavingsGoal>> goals() =>
      ApiResponse<List<SavingsGoal>>.ok(_goals.findAll());

  @override
  ApiResponse<SavingsGoal> goal(String id) {
    final found = _goals.findById(id);
    if (found == null) {
      return ApiResponse<SavingsGoal>.failure(
        code: 404,
        message: 'That goal no longer exists',
      );
    }
    return ApiResponse<SavingsGoal>.ok(found);
  }

  @override
  Future<ApiResponse<Transaction>> transfer({
    required String idempotencyKey,
    required String recipient,
    required int amountKobo,
    String? bankName,
  }) => _handle(
    () => _transfers.execute(
      idempotencyKey: idempotencyKey,
      recipient: recipient,
      amountKobo: amountKobo,
      bankName: bankName,
    ),
    successCode: 201,
  );

  @override
  Future<ApiResponse<Transaction>> fund({
    required String idempotencyKey,
    required int amountKobo,
  }) => _handle(
    () => _funding.execute(
      idempotencyKey: idempotencyKey,
      amountKobo: amountKobo,
    ),
    successCode: 201,
  );

  @override
  Future<ApiResponse<SavingsGoal>> contribute({
    required String idempotencyKey,
    required String goalId,
    required int amountKobo,
  }) => _handle(
    () => _savings.contribute(
      idempotencyKey: idempotencyKey,
      goalId: goalId,
      amountKobo: amountKobo,
    ),
  );

  @override
  Future<ApiResponse<SavingsGoal>> createGoal({
    required String id,
    required String name,
    required int targetKobo,
    required DateTime targetDate,
  }) => _handle(
    () => _savings.createGoal(
      id: id,
      name: name,
      targetKobo: targetKobo,
      targetDate: targetDate,
    ),
    successCode: 201,
  );

  @override
  Future<ApiResponse<SavingsGoal>> updateGoal({
    required String goalId,
    required String name,
    required int targetKobo,
    required DateTime targetDate,
  }) => _handle(
    () => _savings.updateGoal(
      goalId: goalId,
      name: name,
      targetKobo: targetKobo,
      targetDate: targetDate,
    ),
  );

  @override
  Future<ApiResponse<bool>> deleteGoal(String goalId) => _handle(() async {
    await _savings.deleteGoal(goalId);
    return true;
  });

  /// Wipes the server, including the applied keys. Demo and test use only.
  Future<void> reset() async {
    await _accounts.clear();
    await _transactions.clear();
    await _goals.clear();
    await _idempotency.clear();
  }
}
