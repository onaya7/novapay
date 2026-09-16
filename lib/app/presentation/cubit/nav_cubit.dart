import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

/// Which tab the shell is showing.
///
/// A cubit rather than local state because descendants change it: the wallet's
/// Activity header and its History action both switch tab.
@injectable
class NavCubit extends Cubit<int> {
  NavCubit() : super(0);

  void select(int index) => emit(index);
}
