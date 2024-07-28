import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';

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
                      widget.isApple ? const Icon(Icons.apple, color: Colors.black, size: 30) : SvgPicture.asset('images/googleIcon.svg', height: 24),
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

  Future<void> _authenticate() async {

    if (!mounted) return;

    try {
      final authService = ref.read(authServiceProvider);
      final success = await (widget.isApple
          ? authService.signInWithApple()
          : authService.signInWithGoogle());

      if (!mounted) return;

      if (success) {
        final userExists = await ref
            .read(firestoreServiceProvider)
            .checkExistingUser(authService.uid);
        
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(userExists ? '/' : '/login/explore');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          // TODO: Load error messages from app texts as well
          const SnackBar(content: Text("Error authenticating, please try again."), backgroundColor: AppStyle.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication error: $e"), backgroundColor: AppStyle.red),
      );
    }
  }
}