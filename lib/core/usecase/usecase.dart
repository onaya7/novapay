import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:novapay/core/error/failure.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// A live stream has no single completion, so no `Either` per frame.
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
