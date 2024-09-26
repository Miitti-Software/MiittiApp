import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/confirmdialog.dart';

/// A button that deletes the user's account when tapped.
class DeleteAccountButton extends ConsumerStatefulWidget {
  const DeleteAccountButton({super.key});

  @override
  ConsumerState<DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends ConsumerState<DeleteAccountButton> {

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDeleteConfirmation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.highlight_off, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 16),
          Text(
            ref.watch(remoteConfigServiceProvider).get<String>('delete-account-button'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before deleting the user's account.
  Future<void> _showDeleteConfirmation() async {
    if (await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: ref.watch(remoteConfigServiceProvider).get<String>('delete-account-confirmation-title'),
        mainText: ref.watch(remoteConfigServiceProvider).get<String>('delete-account-confirmation-text'),
        confirmButtonText: ref.watch(remoteConfigServiceProvider).get<String>('cancel-button'),
        cancelButtonText: ref.watch(remoteConfigServiceProvider).get<String>('delete-account-confirmation-button'),
      ),
    ) == true) {
      _showLoadingOverlay();
      try {
        context.go('/login');
        await ref.read(userStateProvider.notifier).deleteUser();
      } catch (error) {
        _showErrorSnackBar('${ref.watch(remoteConfigServiceProvider).get<String>('delete-account-error')} ${ref.watch(remoteConfigServiceProvider).get<String>('generic-error-action-prompt')}');
        if (kDebugMode) debugPrint('Error deleting account: $error');
      }
    }
  }

  /// Shows a loading overlay while the account is being deleted in order to prevent the user from interacting with the app.
  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}