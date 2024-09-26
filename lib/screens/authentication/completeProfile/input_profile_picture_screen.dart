import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    final userData = ref.read(userStateProvider).data;
    if (userData.profilePicture != null) {
      if (ref.read(userStateProvider).isAnonymous) {
        image = File(userData.profilePicture!);
      } else {
        imageUrl = userData.profilePicture;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    final isAnonymous = ref.watch(userStateProvider).isAnonymous;
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
              if (image != null)
                SizedBox(
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
              else if (imageUrl != null)
                SizedBox(
                  height: 350,
                  width: 350,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                )
              else
                Container(
                  height: 350,
                  width: 350,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(25),
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
                      foregroundColor: Theme.of(context).colorScheme.onSurface.withAlpha(25), 
                      backgroundColor: Theme.of(context).colorScheme.onSurface.withAlpha(13), 
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withAlpha(25), width: 1),
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
                      foregroundColor: Theme.of(context).colorScheme.onSurface.withAlpha(25), 
                      backgroundColor: Theme.of(context).colorScheme.onSurface.withAlpha(13), 
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withAlpha(25), width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),
          
          ForwardButton(
            buttonText: isAnonymous ? config.get<String>('next-button') : config.get<String>('save-button'),
            onPressed: () async {
              if (image != null || imageUrl != null) {
                if (isAnonymous) {
                  context.push('/login/complete-profile/activities');
                } else {
                  await ref.read(userStateProvider.notifier).updateUserProfilePicture(image!.path);
                  context.pop();
                }
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
          imageUrl = null; // Clear the imageUrl when a new image is selected
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