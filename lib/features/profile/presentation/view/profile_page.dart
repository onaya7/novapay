import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_input_field.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/section_header.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:novapay/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:novapay/gen/assets.gen.dart';
import 'package:novapay/l10n/l10n.dart';

/// The cubit is app-wide and started by `App`, so this reads it rather than
/// creating one.
class ProfilePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const ProfileView();
}

class ProfileView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: context.l10n.profileLabel,
      showBackButton: false,
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state) {
          ProfileLoading() => const LoadingIndicator(),
          ProfileFailure(:final message) => AppErrorState(
            message: message,
            onRetry: context.read<ProfileCubit>().start,
          ),
          ProfileReady(:final profile) => _Ready(profile: profile),
        },
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppSize.md, bottom: AppSize.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                AppAvatar(
                  icon: Icons.person_outline,
                  image: Assets.images.profile.provider(),
                  size: 88,
                ),
                AppSize.h(AppSize.smd),
                Text(
                  profile.hasName ? profile.displayName : l10n.addYourNameLabel,
                  style: texts.titleLarge,
                ),
                AppSize.h(AppSize.xs),
                Text(
                  l10n.thisDeviceOnlyLabel,
                  style: texts.bodySmall?.copyWith(color: colors.subtext),
                ),
              ],
            ),
          ),
          AppSize.h(AppSize.xl),
          SettingsGroup(
            title: l10n.youSectionTitle,
            children: [_NameField(profile: profile)],
          ),
          AppSize.h(AppSize.lg),
          SettingsGroup(
            title: l10n.appearanceSectionTitle,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSize.smd),
                child: ThemeModeToggle(),
              ),
            ],
          ),
          AppSize.h(AppSize.lg),
          SettingsGroup(
            title: l10n.languageSectionTitle,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSize.smd),
                child: LocaleToggle(),
              ),
            ],
          ),
          AppSize.h(AppSize.lg),
          SettingsGroup(
            title: l10n.aboutSectionTitle,
            children: [
              SettingsRow(label: l10n.versionLabel, value: '1.0.0'),
              SettingsRow(
                label: l10n.moneyModelLabel,
                value: l10n.moneyModelValue,
              ),
            ],
          ),
          AppSize.h(AppSize.lg),
          Text(
            l10n.disclaimerText,
            style: texts.bodySmall?.copyWith(color: colors.subtext),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({required this.profile});

  final UserProfile profile;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.profile.displayName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSize.smd),
      child: CustomInputField(
        label: l10n.yourNameLabel,
        hint: l10n.yourNameHint,
        helper: l10n.yourNameHelper,
        controller: _controller,
        onChanged: context.read<ProfileCubit>().rename,
      ),
    );
  }
}
