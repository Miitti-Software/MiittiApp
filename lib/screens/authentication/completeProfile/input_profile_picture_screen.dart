import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';

class InputProfilePictureScreen extends ConsumerStatefulWidget {
  const InputProfilePictureScreen({super.key});

  @override
  _InputProfilePictureScreenState createState() =>
      _InputProfilePictureScreenState();
}

class _InputProfilePictureScreenState
    extends ConsumerState<InputProfilePictureScreen> {
  File? image;

  @override
  void initState() {
    super.initState();
    final userData = ref.read(userStateProvider).data;
    if (userData.profilePicture != null) {
      image = File(userData.profilePicture!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    ref.read(analyticsServiceProvider).logScreenView('input_profile_picture_screen');

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(config.get<String>('input-profile-picture-title'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('input-profile-picture-disclaimer'),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSizes.verticalSeparationPadding),

          Column(
              children: [
                image != null
                    ? SizedBox(
                        height: 350,
                        width: 350,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            image!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        height: 350,
                        width: 350,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Center(
                          child: Text(
                            config.get<String>('input-profile-picture-placeholder'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                const SizedBox(
                  height: AppSizes.minVerticalPadding,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        selectImage(context, isCamera: false);
                      },
                      icon: Icon(Icons.image_search_rounded, color: Theme.of(context).colorScheme.onSurface),
                      label: Text(
                        config.get<String>('input-profile-picture-gallery-button'),
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), 
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), 
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), width: 1),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        selectImage(context, isCamera: true);
                      },
                      icon: Icon(Icons.photo_camera_rounded, color: Theme.of(context).colorScheme.onSurface),
                      label: Text(
                        config.get<String>('input-profile-picture-camera-button'),
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), 
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), 
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          const Spacer(),
          
          ForwardButton(
            buttonText: config.get<String>('forward-button'),
            onPressed: () {
              if (image != null) {
                context.push('/login/complete-profile/activities');
              } else {
                ErrorSnackbar.show(
                    context, config.get<String>('invalid-profile-picture-missing'));
              }
            },
          ),
          const SizedBox(height: AppSizes.minVerticalPadding),
          BackwardButton(
            buttonText: config.get<String>('back-button'),
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSizes.minVerticalEdgePadding),
        ],
      ),
    );
  }

  Future<File?> selectImage(BuildContext context, {required bool isCamera}) async {
    try {
      final XFile? pickedImage =
          await ImagePicker().pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery, maxHeight: 1024, maxWidth: 1024);
      if (pickedImage != null) {
        setState(() {
          image = File(pickedImage.path);
          ref.watch(userStateProvider.notifier).update((state) => state.copyWith(
            data: ref.watch(userStateProvider).data.setProfilePicture(image!.path)
          ));
        });
      }
    } catch (e) {
      if (context.mounted) {
        debugPrint(e.toString());
        ErrorSnackbar.show(context, ref.watch(remoteConfigServiceProvider).get<String>('select-image-error'));
      }
    }
    return image;
  }

}
