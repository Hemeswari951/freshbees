import 'package:flutter/foundation.dart';

/// Global "whiteboard" — total cart item count.
/// Every cart icon in the app watches this value and updates its badge
/// automatically whenever it changes. Updated centrally from
/// CartService (addToCart / removeItem), so no screen needs to manage
/// this manually.
final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);