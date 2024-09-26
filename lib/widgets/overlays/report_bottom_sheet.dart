import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/fields/filled_text_area.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
import 'package:miitti_app/widgets/overlays/success_snackbar.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';

class ReportBottomSheet extends ConsumerStatefulWidget {
  final bool isActivity;
  final String id;

  const ReportBottomSheet({
    super.key,
    required this.isActivity,
    required this.id,
  });

  static void show({
    required BuildContext context,
    required bool isActivity,
    required String id,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context) {
        return ReportBottomSheet(isActivity: isActivity, id: id);
      },
    );
  }

  @override
  _ReportBottomSheetState createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<ReportBottomSheet> {
  final TextEditingController _commentsController = TextEditingController();
  final List<String> _selectedReasons = [];
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    final reportingReasons = config.getTuplesList<String>(widget.isActivity ? 'activity_report_reasons' : 'profile_report_reasons');

    final title = config.get<String>(widget.isActivity ? 'report-activity-title' : 'report-profile-title');
    final reasonTitle = config.get<String>(widget.isActivity ? 'report-activity-reason-title' : 'report-profile-reason-title');
    final textfieldTitle = config.get<String>(widget.isActivity? 'report-activity-textfield-title' : 'report-profile-textfield-title');
    final textfieldPlaceholder = config.get<String>(widget.isActivity? 'report-activity-textfield-placeholder' : 'report-profile-textfield-placeholder');
    final confirmText = config.get<String>(widget.isActivity? 'report-activity-button' : 'report-profile-button');
    final cancelText = config.get<String>('cancel-button');
    final disclaimer = config.get<String>(widget.isActivity? 'report-activity-disclaimer' : 'report-profile-disclaimer');

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: (MediaQuery.of(context).size.width - AppSizes.fullContentWidth) / 2,
          right: (MediaQuery.of(context).size.width - AppSizes.fullContentWidth) / 2,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.minVerticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(
              color: Theme.of(context).colorScheme.onPrimary,
              thickness: 2.0,
              indent: 100,
              endIndent: 100,
            ),
            const SizedBox(height: AppSizes.minVerticalPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.verticalSeparationPadding),
            Text(
              reasonTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 250,
                ),
                child: PermanentScrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: reportingReasons.map((reason) {
                        final isSelected = _selectedReasons.contains(reason.item1);
                        return CheckboxListTile(
                          checkboxShape: const CircleBorder(),
                          title: Text(
                            reason.item2,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.labelMedium?.color,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedReasons.add(reason.item1);
                              } else {
                                _selectedReasons.remove(reason.item1);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          checkColor: Theme.of(context).colorScheme.primary,
                          activeColor: Theme.of(context).colorScheme.primary,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.verticalSeparationPadding),
            Text(
              textfieldTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            FilledTextArea(
              controller: _commentsController,
              hintText: textfieldPlaceholder,
            ),
            const SizedBox(height: AppSizes.verticalSeparationPadding),
            ForwardButton(
              buttonText: confirmText,
              onPressed: () async {
                final firestoreService = ref.read(firestoreServiceProvider);

                if (_selectedReasons.isEmpty) {
                  ErrorSnackbar.show(context, config.get<String>('invalid-report-missing-reason'));
                  return;
                }

                context.pop();

                if (widget.isActivity) {
                  SuccessSnackbar.show(context, config.get<String>('report-activity-success'));
                  await firestoreService.reportActivity(
                    widget.id,
                    _selectedReasons,
                    _commentsController.text,
                  );
                } else {
                  SuccessSnackbar.show(context, config.get<String>('report-profile-success'));
                  await firestoreService.reportUser(
                    widget.id,
                    _selectedReasons,
                    _commentsController.text,
                  );
                }

              },
            ),
            const SizedBox(height: AppSizes.minVerticalPadding),
            BackwardButton(
              buttonText: cancelText,
              onPressed: () {
                context.pop();
              },
            ),
            const SizedBox(height: AppSizes.minVerticalPadding),
            Text(
              disclaimer,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: AppSizes.minVerticalPadding),
          ],
        ),
      ),
    );
  }
}