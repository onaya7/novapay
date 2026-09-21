import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/core/time/clock_scope.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:novapay/features/wallet/domain/entities/activity_item.dart';
import 'package:novapay/features/wallet/domain/entities/wallet_snapshot.dart';
import 'package:novapay/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:novapay/features/wallet/presentation/view/wallet_page.dart';
import 'package:novapay/l10n/l10n.dart';

import '../../../../helpers/test_clock.dart';

class _MockWalletCubit extends MockCubit<WalletState> implements WalletCubit;

class _MockProfileCubit extends MockCubit<ProfileState> implements ProfileCubit;

// Pinned, or the greeting and the day labels drift with the wall clock.
final DateTime _pinnedNow = DateTime(2026, 9, 17, 9);

WalletSnapshot _readySnapshot() => WalletSnapshot(
  confirmedKobo: 24800000,
  pendingKobo: 500000,
  activity: [
    ActivityItem(
      id: '1',
      title: 'To Guaranty Trust Bank, ****6789',
      amountKobo: -500000,
      occurredAt: DateTime(2026, 9, 16, 9),
      status: ActivityStatus.pending,
    ),
    ActivityItem(
      id: '2',
      title: 'Savings contribution',
      amountKobo: -250000,
      occurredAt: DateTime(2026, 9, 15, 18, 30),
      status: ActivityStatus.settled,
    ),
    ActivityItem(
      id: '3',
      title: 'From diaspora remittance',
      amountKobo: 1500000,
      occurredAt: DateTime(2026, 9, 14, 8),
      status: ActivityStatus.settled,
    ),
  ],
);

void main() {
  final profile = _MockProfileCubit();
  whenListen(
    profile,
    const Stream<ProfileState>.empty(),
    initialState: const ProfileState.ready(UserProfile(displayName: 'Ada')),
  );

  Widget wrap(WalletState state, {ThemeData? theme}) {
    final wallet = _MockWalletCubit();
    when(wallet.refresh).thenAnswer((_) async {});
    whenListen(wallet, const Stream<WalletState>.empty(), initialState: state);

    return MultiBlocProvider(
      providers: [
        BlocProvider<WalletCubit>.value(value: wallet),
        BlocProvider<ProfileCubit>.value(value: profile),
      ],
      child: ClockScope(
        clock: TestClock(_pinnedNow),
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WalletView(),
        ),
      ),
    );
  }

  unawaited(
    goldenTest(
      'wallet home renders its loading, empty and populated states',
      fileName: 'wallet_home',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          GoldenTestScenario(
            name: 'loading',
            child: SizedBox(
              width: 390,
              height: 844,
              child: wrap(const WalletState.loading()),
            ),
          ),
          GoldenTestScenario(
            name: 'empty',
            child: SizedBox(
              width: 390,
              height: 844,
              child: wrap(
                const WalletState.ready(
                  WalletSnapshot(
                    confirmedKobo: 0,
                    pendingKobo: 0,
                    activity: [],
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'ready with activity',
            child: SizedBox(
              width: 390,
              height: 844,
              child: wrap(WalletState.ready(_readySnapshot())),
            ),
          ),
          GoldenTestScenario(
            name: 'ready with activity, dark',
            child: SizedBox(
              width: 390,
              height: 844,
              child: wrap(
                WalletState.ready(_readySnapshot()),
                theme: AppTheme.dark,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
