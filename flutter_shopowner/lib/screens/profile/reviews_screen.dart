import 'package:flutter/material.dart';
import '../../widgets/app_colors.dart';
import '../../services/profile_service.dart';

/// "Reviews and ratings" screen — opened from ProfileScreen's Customers
/// card. Unlike ShopDetailsScreen, this DOES need a fresh backend call
/// (GET /shop/reviews) because the individual review list was never
/// fetched by ProfileScreen — only the avgRating/reviewCount summary was.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final List<ShopReview> _reviews = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reviews = await ProfileService.getReviews(page: 1, limit: _limit);
      setState(() {
        _reviews
          ..clear()
          ..addAll(reviews);
        _page = 1;
        _hasMore = reviews.length == _limit;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await ProfileService.getReviews(
        page: _page + 1,
        limit: _limit,
      );
      setState(() {
        _reviews.addAll(next);
        _page += 1;
        _hasMore = next.length == _limit;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: const Text(
          'Reviews and ratings',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorState()
          : _reviews.isEmpty
          ? _emptyState()
          : RefreshIndicator(
              onRefresh: _load,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                    _loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index >= _reviews.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return _reviewCard(_reviews[index]);
                  },
                ),
              ),
            ),
    );
  }

  Widget _errorState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, size: 34, color: AppColors.inkSoft),
        const SizedBox(height: 10),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(onPressed: _load, child: const Text('Try again')),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.star_outline_rounded, size: 34, color: AppColors.inkSoft),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'No reviews yet',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Reviews customers leave on your products will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(ShopReview r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.customerName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 15,
                    color: const Color(0xFFF39C12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            r.productName,
            style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
          ),
          if (r.reviewText != null && r.reviewText!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.reviewText!,
              style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.35),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _formatDate(r.createdAt),
            style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}