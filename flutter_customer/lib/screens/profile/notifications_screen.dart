import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _text = Color(0xFF252525);
  static const Color _muted = Color(0xFF777777);
  static const Color _card = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // appBar: AppBar(
      //   backgroundColor: _bg,
      //   elevation: 0,
      //   surfaceTintColor: Colors.transparent,

      //   leading: IconButton(
      //     icon: const Icon(
      //       Icons.arrow_back,
      //       color: _text,
      //     ),
      //     onPressed: () => Navigator.pop(context),
      //   ),

      //   title: const Text(
      //     'Notifications',
      //     style: TextStyle(
      //       color: _text,
      //       fontWeight: FontWeight.w700,
      //       fontSize: 20,
      //     ),
      //   ),

      //   actions: [
      //     TextButton(
      //       onPressed: () {
      //         // UI only for now.
      //         // Later this can call:
      //         // NotificationService.markAllAsRead()
      //       },
      //       child: const Text(
      //         'Mark all read',
      //         style: TextStyle(
      //           color: _accent,
      //           fontSize: 12,
      //           fontWeight: FontWeight.w600,
      //         ),
      //       ),
      //     ),
      //   ],
      // ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _sectionTitle('TODAY'),

            _notificationCard(
              icon: Icons.local_offer_outlined,
              title: 'Special offer for you',
              message:
                  'Get extra savings on selected fashion products today.',
              time: '10 min ago',
              unread: true,
            ),

            _notificationCard(
              icon: Icons.favorite_border,
              title: 'Your wishlist is waiting',
              message:
                  'Some products from your wishlist are still available.',
              time: '1 hour ago',
              unread: true,
            ),

            const SizedBox(height: 20),

            _sectionTitle('EARLIER'),

            _notificationCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Order update',
              message:
                  'Your recent order has been successfully confirmed.',
              time: 'Yesterday',
              unread: false,
            ),

            _notificationCard(
              icon: Icons.location_on_outlined,
              title: 'Discover nearby stores',
              message:
                  'Explore fashion stores available near your location.',
              time: '2 days ago',
              unread: false,
            ),

            _notificationCard(
              icon: Icons.card_giftcard_outlined,
              title: 'New rewards available',
              message:
                  'Check out the latest offers and rewards available for you.',
              time: '3 days ago',
              unread: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: _muted,
        ),
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool unread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: _accent,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),

                      if (unread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(
                            top: 5,
                            left: 6,
                          ),
                          decoration: const BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    message,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}