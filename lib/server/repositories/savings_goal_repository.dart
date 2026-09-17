import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';
import 'package:novapay/server/models/savings_goal.dart';

abstract class SavingsGoalRepository {
  List<SavingsGoal> findAll();
  SavingsGoal? findById(String id);
  Future<void> insert(SavingsGoal goal);
  Future<void> update(SavingsGoal goal);
  Future<void> delete(String id);
  Future<void> clear();
}

@LazySingleton(as: SavingsGoalRepository)
class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  SavingsGoalRepositoryImpl(this._db);

  final LocalDataStorage _db;

  static const String _key = 'server_savings_goals';

  @override
  List<SavingsGoal> findAll() {
    final raw = _db.read<String>(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((row) => SavingsGoal.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  SavingsGoal? findById(String id) {
    for (final goal in findAll()) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  @override
  Future<void> insert(SavingsGoal goal) => _saveAll([...findAll(), goal]);

  @override
  Future<void> update(SavingsGoal goal) => _saveAll([
    for (final existing in findAll())
      if (existing.id == goal.id) goal else existing,
  ]);

  Future<void> _saveAll(List<SavingsGoal> goals) => _db.write<String>(
    _key,
    jsonEncode(goals.map((g) => g.toJson()).toList()),
  );

  @override
  Future<void> delete(String id) => _saveAll([
    for (final goal in findAll())
      if (goal.id != id) goal,
  ]);

  @override
  Future<void> clear() => _db.delete(_key);
}
