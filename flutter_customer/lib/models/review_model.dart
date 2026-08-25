// ── individual review (used both in the list and as "your review") ───────
class ReviewModel {
  final int reviewId;
  final int rating;
  final String reviewText;
  final DateTime createdAt;
  final String customerName;
  final String? customerProfileImage;

  ReviewModel({
    required this.reviewId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    this.customerName = '',
    this.customerProfileImage,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'] ?? 0,
      rating: json['rating'] ?? 0,
      reviewText: json['reviewText'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      // eligibility's "existingReview" doesn't include these two keys —
      // defaulting to '' / null keeps this model usable for both shapes.
      customerName: json['customerName'] ?? '',
      customerProfileImage: json['customerProfileImage'],
    );
  }
}

// ── one row of the star breakdown, e.g. { count: 80, percent: 63 } ────────
class RatingBreakdownEntry {
  final int count;
  final int percent;

  RatingBreakdownEntry({required this.count, required this.percent});

  factory RatingBreakdownEntry.fromJson(Map<String, dynamic> json) {
    return RatingBreakdownEntry(
      count: json['count'] ?? 0,
      percent: json['percent'] ?? 0,
    );
  }
}

class ReviewSummaryModel {
  final double avgRating;
  final int totalReviews;
  final Map<int, RatingBreakdownEntry> breakdown; // keys: 5,4,3,2,1

  ReviewSummaryModel({
    required this.avgRating,
    required this.totalReviews,
    required this.breakdown,
  });

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = <int, RatingBreakdownEntry>{};
    rawBreakdown.forEach((key, value) {
      breakdown[int.parse(key)] = RatingBreakdownEntry.fromJson(value);
    });
    return ReviewSummaryModel(
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      breakdown: breakdown,
    );
  }
}

class ReviewPaginationModel {
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;

  ReviewPaginationModel({
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
  });

  factory ReviewPaginationModel.fromJson(Map<String, dynamic> json) {
    return ReviewPaginationModel(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

// ── GET /reviews response, bundled together ────────────────────────────
class ProductReviewsResult {
  final ReviewSummaryModel summary;
  final List<ReviewModel> reviews;
  final ReviewPaginationModel pagination;

  ProductReviewsResult({
    required this.summary,
    required this.reviews,
    required this.pagination,
  });

  factory ProductReviewsResult.fromJson(Map<String, dynamic> json) {
    return ProductReviewsResult(
      summary: ReviewSummaryModel.fromJson(json['summary']),
      reviews: (json['reviews'] as List)
          .map((e) => ReviewModel.fromJson(e))
          .toList(),
      pagination: ReviewPaginationModel.fromJson(json['pagination']),
    );
  }
}

// ── GET /reviews/eligibility response ──────────────────────────────────
class ReviewEligibilityModel {
  final bool isVerifiedPurchase;
  final bool alreadyReviewed;
  final ReviewModel? existingReview;
  final bool canSubmit;

  ReviewEligibilityModel({
    required this.isVerifiedPurchase,
    required this.alreadyReviewed,
    this.existingReview,
    required this.canSubmit,
  });

  factory ReviewEligibilityModel.fromJson(Map<String, dynamic> json) {
    return ReviewEligibilityModel(
      isVerifiedPurchase: json['isVerifiedPurchase'] ?? false,
      alreadyReviewed: json['alreadyReviewed'] ?? false,
      existingReview: json['existingReview'] == null
          ? null
          : ReviewModel.fromJson(json['existingReview']),
      canSubmit: json['canSubmit'] ?? false,
    );
  }
}