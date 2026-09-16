import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novapay/core/error/failure.dart';
import 'package:novapay/core/usecase/usecase.dart';

class _Doubler extends UseCase<int, int> {
  @override
  Future<Either<Failure, int>> call(int params) async => Right(params * 2);
}

class _Ticker extends StreamUseCase<int, NoParams> {
  @override
  Stream<int> call(NoParams params) => Stream<int>.fromIterable(const [1, 2]);
}

void main() {
  test('NoParams instances are interchangeable', () {
    expect(const NoParams(), const NoParams());
    expect(const NoParams().props, isEmpty);
  });

  test('a usecase returns Either', () async {
    expect(await _Doubler()(21), const Right<Failure, int>(42));
  });

  test('a stream usecase yields frames without an Either per frame', () {
    expect(
      _Ticker()(const NoParams()),
      emitsInOrder(<Object>[1, 2, emitsDone]),
    );
  });
}
