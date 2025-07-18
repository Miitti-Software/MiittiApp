import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';

/// A button handling authentication with Google or Apple.
class AuthButton extends ConsumerStatefulWidget {
  final bool isApple;

  const AuthButton({super.key, this.isApple = false});

  @override
  ConsumerState<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends ConsumerState<AuthButton> {
  Future<void>? _authFuture;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.fullContentWidth,
      child: FutureBuilder<void>(
        future: _authFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return ElevatedButton(
            onPressed: isLoading ? null : _handleAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
            child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.isApple ? const Icon(Icons.apple, color: Colors.black, size: 30) : SvgPicture.asset(AppGraphics.googleIcon, height: 24),
                    const SizedBox(width: 12),
                    Text(
                      ref.read(remoteConfigServiceProvider).get<String>(widget.isApple ? 'auth-apple' : 'auth-google'),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.surface),
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }

  Future<void> _handleAuth() async {
    setState(() {
      _authFuture = _authenticate();
    });
  }

  /// Authenticates the user with Google or Apple and navigates to the next screen depending on whether the user already exists in the database.
  Future<void> _authenticate() async {

    if (!mounted) return;

    try {
      final userState = ref.read(userStateProvider.notifier);
      final success = await (widget.isApple ? userState.signIn(true) : userState.signIn(false));

      if (!mounted) return;

      if (success) {
        final userExists = await ref.read(firestoreServiceProvider).fetchUser(ref.read(userStateProvider).uid!) != null;
        
        if (!mounted) return;
        
        context.go(userExists ? '/' : '/login/welcome');
        
      } else {
        ErrorSnackbar.show(
          context,
          ref.read(remoteConfigServiceProvider).get<String>('interrupted-login')
        );
      }
    } catch (error) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('Error logging in: $error');
      ErrorSnackbar.show(
        context,
        "${ref.read(remoteConfigServiceProvider).get<String>('login-error')} ${ref.read(remoteConfigServiceProvider).get<String>('generic-error-action-prompt')}"
      );
    }
  }
}