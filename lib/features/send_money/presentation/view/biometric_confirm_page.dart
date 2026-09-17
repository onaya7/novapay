import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/auth/biometric_authenticator.dart';
import 'package:novapay/core/components/custom_button.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/core/injections/injection.dart';
import 'package:novapay/features/send_money/presentation/cubit/send_money_cubit.dart';
import 'package:novapay/l10n/l10n.dart';

class BiometricConfirmPage extends StatefulWidget {
  const new({this.authenticator, super.key});

  final BiometricAuthenticator? authenticator;

  @override
  State<BiometricConfirmPage> createState() => _BiometricConfirmPageState();
}

class _BiometricConfirmPageState extends State<BiometricConfirmPage> {
  bool _confirming = false;

  Future<void> _confirm(SendMoneyCubit cubit) async {
    setState(() => _confirming = true);
    final authenticator = widget.authenticator ?? sl<BiometricAuthenticator>();
    final authenticated = await authenticator.authenticate();
    if (!authenticated) {
      if (mounted) setState(() => _confirming = false);
      return;
    }
    await cubit.submit();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SendMoneyCubit>();
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final amount = cubit.state.draft.amount.format();

    return CustomScaffold(
      title: l10n.biometricConfirmTitle,
      bottomBar: CustomButton(
        label: l10n.biometricConfirmButton,
        isLoading: _confirming,
        onPressed: _confirming ? null : () => unawaited(_confirm(cubit)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSize.h(AppSize.xxl),
          Center(
            child: Container(
              height: 96,
              width: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.brandSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fingerprint,
                size: AppSize.xl,
                color: colors.primaryStrong,
              ),
            ),
          ),
          AppSize.h(AppSize.lg),
          Text(
            l10n.biometricConfirmBody(amount),
            textAlign: TextAlign.center,
            style: texts.bodyMedium?.copyWith(color: colors.textSubheading),
          ),
        ],
      ),
    );
  }
}
