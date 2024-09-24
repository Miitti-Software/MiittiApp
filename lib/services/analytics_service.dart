import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/main.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/models/commercial_activity.dart';
import 'package:miitti_app/models/commercial_spot.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/user_created_activity.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  AnalyticsService() {
    _setDefaults();
  }

  FirebaseAnalytics get instance => _analytics;

  Future<void> _setDefaults() async {
    await _analytics.setDefaultEventParameters({
      'app_version': appVersion,
    });
  }

  Future<void> logUserCreatedActivityCreated(UserCreatedActivity activity, MiittiUser user) async {
    await _analytics.logEvent(
      name: 'activity_created',
      parameters: {
        'id': activity.id,
        'address': activity.address,
        'category': activity.category,
        'max_participants': activity.maxParticipants,
        'creator_age': activity.creatorAge,
        'creator_gender': activity.creatorGender,
        'creator_primary_occupation': user.occupationalStatuses.isNotEmpty ? user.occupationalStatuses[0] : 'none',
        'creator_primary_organization': user.organizations.isNotEmpty ? user.organizations[0] : 'none',
        },
    );
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logActivityJoined(String activityId) async {
    await _analytics.logEvent(
      name: 'activity_joined',
      parameters: {'activity_id': activityId},
    );
  }

  Future<void> logBannerAdView(AdBannerData adBanner) async {
    await _analytics.logEvent(
      name: 'banner_ad_viewed',
      parameters: {
        'id': adBanner.id,
        'organization': adBanner.organization,
      },
    );
  }

  Future<void> logCommercialSpotView(CommercialSpot commercialSpot) async {
    await _analytics.logEvent(
      name: 'commercial_spot_viewed',
      parameters: {
        'id': commercialSpot.id,
        'organization': commercialSpot.organization,
      },
    );
  }

  Future<void> logCommercialActivityView(CommercialActivity activity) async {
    await _analytics.logEvent(
      name: 'commercial_activity_viewed',
      parameters: {
        'id': activity.id,
        'title': activity.title,
        'category': activity.category,
        'organization': activity.creator,
      },
    );
  }

  Future<void> logBannerAdClicked(AdBannerData adBanner) async {
    await _analytics.logEvent(
      name: 'banner_ad_clicked',
      parameters: {
        'id': adBanner.id,
        'organization': adBanner.organization,
      },
    );
  }

  Future<void> logUserDeleted() {
    return _analytics.logEvent(
      name: 'user_deleted'
      // TODO: Add reason for deletion
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});