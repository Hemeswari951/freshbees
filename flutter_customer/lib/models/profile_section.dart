import 'package:flutter/material.dart';

enum ProfileSection {
  overview,
  orders,
  coupons,
  savedCards,
  savedAddress,
  helpCenter,
  notificationSettings,
  faqs,
  aboutUs,
  termsPolicies,
}

extension ProfileSectionX on ProfileSection {
  String get label {
    switch (this) {
      case ProfileSection.overview:
        return 'Overview';
      case ProfileSection.orders:
        return 'Orders';
      case ProfileSection.coupons:
        return 'Coupons';
      case ProfileSection.savedCards:
        return 'Saved Cards';
      case ProfileSection.savedAddress:
        return 'Saved Address';
      case ProfileSection.helpCenter:
        return 'Help Center';
      case ProfileSection.notificationSettings:
        return 'Notification Settings';
      case ProfileSection.faqs:
        return 'FAQs';
      case ProfileSection.aboutUs:
        return 'About Us';
      case ProfileSection.termsPolicies:
        return 'Terms & Policies';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileSection.overview:
        return Icons.dashboard_outlined;
      case ProfileSection.orders:
        return Icons.receipt_long_outlined;
      case ProfileSection.coupons:
        return Icons.local_offer_outlined;
      case ProfileSection.savedCards:
        return Icons.credit_card_outlined;
      case ProfileSection.savedAddress:
        return Icons.location_on_outlined;
      case ProfileSection.helpCenter:
        return Icons.help_outline;
      case ProfileSection.notificationSettings:
        return Icons.notifications_none;
      case ProfileSection.faqs:
        return Icons.quiz_outlined;
      case ProfileSection.aboutUs:
        return Icons.info_outline;
      case ProfileSection.termsPolicies:
        return Icons.description_outlined;
    }
  }

  /// Used in the query param: /profile/details?section=<this>
  String get slug {
    switch (this) {
      case ProfileSection.overview:
        return 'overview';
      case ProfileSection.orders:
        return 'orders';
      case ProfileSection.coupons:
        return 'coupons';
      case ProfileSection.savedCards:
        return 'saved-cards';
      case ProfileSection.savedAddress:
        return 'saved-address';
      case ProfileSection.helpCenter:
        return 'help-center';
      case ProfileSection.notificationSettings:
        return 'notification-settings';
      case ProfileSection.faqs:
        return 'faqs';
      case ProfileSection.aboutUs:
        return 'about-us';
      case ProfileSection.termsPolicies:
        return 'terms-policies';
    }
  }

  /// Reverse lookup: slug -> enum. Falls back to overview if unknown.
  static ProfileSection fromSlug(String? slug) {
    return ProfileSection.values.firstWhere(
      (s) => s.slug == slug,
      orElse: () => ProfileSection.overview,
    );
  }
}