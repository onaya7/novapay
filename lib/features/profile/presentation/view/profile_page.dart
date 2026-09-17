import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_input_field.dart';
import 'package:novapay/core/components/custom_navigation_bar.dart';
import 'package:novapay/core/components/custom_scaffold.dart';
import 'package:novapay/core/components/section_header.dart';
import 'package:novapay/core/components/state_widgets.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/features/profile/domain/entities/user_profile.dart';
import 'package:novapay/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:novapay/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:novapay/gen/assets.gen.dart';

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
      title: 'Profile',
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

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: AppSize.md,
        bottom: AppSize.xxxl + CustomNavigationBar.reservedHeight(context),
      ),
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
                  profile.hasName ? profile.displayName : 'Add your name',
                  style: texts.titleLarge,
                ),
                AppSize.h(AppSize.xs),
                Text(
                  'This device only',
                  style: texts.bodySmall?.copyWith(color: colors.subtext),
                ),
              ],
            ),
          ),
          AppSize.h(AppSize.xl),
          SettingsGroup(
            title: 'YOU',
            children: [_NameField(profile: profile)],
          ),
          AppSize.h(AppSize.lg),
          const SettingsGroup(
            title: 'APPEARANCE',
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSize.smd),
                child: ThemeModeToggle(),
              ),
            ],
          ),
          AppSize.h(AppSize.lg),
          const SettingsGroup(
            title: 'ABOUT',
            children: [
              SettingsRow(label: 'Version', value: '1.0.0'),
              SettingsRow(label: 'Money', value: 'Held as whole kobo'),
            ],
          ),
          AppSize.h(AppSize.lg),
          Text(
            'A fictional scenario built for evaluation. No real bank systems, '
            'customers or credentials are involved.',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSize.smd),
      child: CustomInputField(
        label: 'Your name',
        hint: 'What should the wallet call you?',
        helper: 'Saved on this device, never sent anywhere',
        controller: _controller,
        onChanged: context.read<ProfileCubit>().rename,
      ),
    );
  }
}
