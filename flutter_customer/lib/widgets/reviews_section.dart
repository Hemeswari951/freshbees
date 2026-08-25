import 'package:flutter/material.dart';

import '../models/review_model.dart';
import '../services/review_service.dart';
import '../services/api_service.dart';
import 'app_colors.dart';

/// Ratings & reviews block for the product detail page. Fetches its own
/// data (summary + reviews + write/edit eligibility) independently of
/// the product-details fetch, so it can refresh on its own after a
/// review is submitted/edited without reloading the whole page.
class ReviewsSection extends StatefulWidget {
  final int productId;

  /// Fired every time a fresh summary is fetched (initial load, sort
  /// change, or after a review is submitted/edited) — lets the parent
  /// screen keep a top-of-page rating badge in sync with this section,
  /// instead of both showing different numbers from different sources.
  final ValueChanged<ReviewSummaryModel>? onSummaryChanged;

  const ReviewsSection({
    super.key,
    required this.productId,
    this.onSummaryChanged,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  ReviewSummaryModel? _summary;
  List<ReviewModel> _reviews = [];
  ReviewPaginationModel? _pagination;
  ReviewEligibilityModel? _eligibility;

  String _sort = 'recent';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ReviewService.getReviews(widget.productId, sort: _sort);
      await _loadEligibility(); // sets _eligibility directly, no throw on failure
      if (!mounted) return;
      setState(() {
        _summary = result.summary;
        _reviews = result.reviews;
        _pagination = result.pagination;
        _isLoading = false;
      });
      widget.onSummaryChanged?.call(result.summary);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load reviews.';
      });
    }
  }

  // Guests don't have a token — skip the call entirely rather than
  // hitting the 401 and showing an error for something that's expected.
  Future<void> _loadEligibility() async {
    final token = ApiService.getToken();
    if (token == null || token.isEmpty) {
      _eligibility = null;
      return;
    }
    try {
      _eligibility = await ReviewService.getEligibility(widget.productId);
    } catch (_) {
      _eligibility = null; // button just won't show if this fails
    }
  }

  Future<void> _loadMore() async {
    if (_pagination == null || _pagination!.page >= _pagination!.totalPages) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = await ReviewService.getReviews(
        widget.productId,
        sort: _sort,
        page: _pagination!.page + 1,
      );
      if (!mounted) return;
      setState(() {
        _reviews = [..._reviews, ...next.reviews];
        _pagination = next.pagination;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _changeSort(String sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _load();
  }

  Future<void> _openWriteOrEditSheet() async {
    final token = ApiService.getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to write a review')),
      );
      return;
    }

    final existing = _eligibility?.existingReview;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WriteReviewSheet(
        productId: widget.productId,
        existingReview: existing,
      ),
    );

    if (saved == true) _load(); // pulls fresh summary/list/eligibility
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_error!, style: TextStyle(color: AppColors.ink.withOpacity(0.6))),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final summary = _summary!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RATINGS & REVIEWS',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: 0.3,
              ),
            ),
            TextButton(
              onPressed: _openWriteOrEditSheet,
              child: Text(
                _eligibility?.alreadyReviewed == true ? 'Edit your review' : 'Write a review',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (summary.totalReviews == 0)
          Text(
            'No reviews yet.',
            style: TextStyle(fontSize: 13, color: AppColors.ink.withOpacity(0.5)),
          )
        else ...[
          _summaryBlock(summary),
          const SizedBox(height: 20),
          _sortRow(),
          const SizedBox(height: 14),
          ..._reviews.map(_reviewCard),
          if (_pagination != null && _pagination!.page < _pagination!.totalPages)
            Center(
              child: TextButton(
                onPressed: _isLoadingMore ? null : _loadMore,
                child: _isLoadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Load more reviews'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _summaryBlock(ReviewSummaryModel summary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              summary.avgRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < summary.avgRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 14,
                  color: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${summary.totalReviews} ${summary.totalReviews == 1 ? 'rating' : 'ratings'}',
              style: TextStyle(fontSize: 11, color: AppColors.ink.withOpacity(0.5)),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final entry = summary.breakdown[star];
              final percent = entry?.percent ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('$star', style: const TextStyle(fontSize: 11, color: AppColors.ink)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, size: 11, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.blush,
                          valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$percent%',
                        style: TextStyle(fontSize: 10.5, color: AppColors.ink.withOpacity(0.5)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _sortRow() {
    Widget chip(String label, String value) {
      final selected = _sort == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          onSelected: (_) => _changeSort(value),
        ),
      );
    }

    return Row(
      children: [
        chip('Most recent', 'recent'),
        chip('Highest rated', 'highest'),
        chip('Lowest rated', 'lowest'),
      ],
    );
  }

  Widget _reviewCard(ReviewModel r) {
    final date = '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.customerName.isNotEmpty ? r.customerName : 'Anonymous',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (star) => Icon(
                    star < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(date, style: TextStyle(fontSize: 10.5, color: AppColors.ink.withOpacity(0.4))),
          if (r.reviewText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.reviewText, style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Write / edit review bottom sheet
// ═══════════════════════════════════════════════════════════════════════

class _WriteReviewSheet extends StatefulWidget {
  final int productId;
  final ReviewModel? existingReview; // null = writing a new review

  const _WriteReviewSheet({required this.productId, this.existingReview});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  late int _rating;
  late final TextEditingController _textController;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 5;
    _textController = TextEditingController(text: widget.existingReview?.reviewText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      if (widget.existingReview != null) {
        await ReviewService.updateReview(
          widget.productId,
          widget.existingReview!.reviewId,
          rating: _rating,
          reviewText: _textController.text.trim(),
        );
      } else {
        await ReviewService.submitReview(
          widget.productId,
          rating: _rating,
          reviewText: _textController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingReview != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Edit your review' : 'Write a review',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 32,
                    color: AppColors.gold,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your experience with this product...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Update review' : 'Submit review'),
            ),
          ),
        ],
      ),
    );
  }
}