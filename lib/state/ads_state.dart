import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/ad_banner_data.dart';
import 'package:miitti_app/state/service_providers.dart';

class AdsState extends StateNotifier<List<AdBannerData>> {
  AdsState(this.ref) : super([]);

  final Ref ref;

  void fetchAds() async {
    List<AdBannerData> ads = await ref.read(firestoreServiceProvider).fetchAdBanners();
    state = ads;
    shuffleAds();
  }

  void shuffleAds() {
    List<AdBannerData> shuffledAds = List.from(state);
    shuffledAds.shuffle();
    state = shuffledAds;
  }

  void incrementAdBannerViewCount(String adId) {
    ref.read(firestoreServiceProvider).incrementAdBannerViewCounter(adId);
  }

  void incrementAdBannerClickCount(String adId) {
    ref.read(firestoreServiceProvider).incrementAdBannerHyperlinkClickCounter(adId);
  }

  void incrementCommercialSpotViewCount(String adId) {
    ref.read(firestoreServiceProvider).incrementCommercialSpotViewCounter(adId);
  }

  void incrementCommercialSpotClickCount(String adId) {
    ref.read(firestoreServiceProvider).incrementCommercialSpotClickCounter(adId);
  }

  void incrementCommercialActivityViewCount(String adId) {
    ref.read(firestoreServiceProvider).incrementCommercialActivityViewCounter(adId);
  }

  void incrementCommercialActivityClickCount(String adId) {
    ref.read(firestoreServiceProvider).incrementCommercialActivityClickCounter(adId);
  }

  void incrementCommercialActivityHyperlinkClickCount(String adId) {
    ref.read(firestoreServiceProvider).incrementCommercialActivityHyperlinkClickCounter(adId);
  }
}

final adsStateProvider = StateNotifierProvider<AdsState, List<AdBannerData>>((ref) {
  return AdsState(ref);
});

class AdViewSessionManager {
  final Set<String> _viewedAdIds = {};

  bool hasViewed(String adId) {
    return _viewedAdIds.contains(adId);
  }

  void markAsViewed(String adId) {
    _viewedAdIds.add(adId);
  }
}

final adViewSessionManager = AdViewSessionManager();