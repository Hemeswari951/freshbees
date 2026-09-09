import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/cart_count.dart';
import '../services/search_service.dart';

class ProductMobileHeader extends StatefulWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onCart;

  const ProductMobileHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onCart,
  });

  @override
  State<ProductMobileHeader> createState() =>
      _ProductMobileHeaderState();
}

class _ProductMobileHeaderState
    extends State<ProductMobileHeader> {
  static const Color _ink = Color(0xFF1F1B16);

  final TextEditingController _searchController =
      TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  final LayerLink _searchLayerLink = LayerLink();

  final OverlayPortalController _searchOverlayController =
      OverlayPortalController();

  Timer? _debounce;

  List<SearchSuggestion> _suggestions = [];

  bool _isSuggesting = false;
  bool _searchExpanded = false;

  @override
  void dispose() {
    _debounce?.cancel();

    if (_searchOverlayController.isShowing) {
      _searchOverlayController.hide();
    }

    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void _openInlineSearch() {
    setState(() {
      _searchExpanded = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _searchFocusNode.requestFocus();
    });
  }


  // ---------------------------------------------------------------------
  // BACK — while search is expanded.
  //
  // NOTE:
  // Previously the back arrow shown inside the search row only called
  // `_closeInlineSearch()`, which just collapses the search UI back to
  // the title row. It did NOT navigate anywhere. That meant a single
  // tap looked like nothing happened (search closes, you're still on
  // the same screen), and the user had to tap back a SECOND time
  // (now from the title row) to actually leave the screen.
  //
  // Fix: tapping back while search is expanded should behave exactly
  // like tapping back normally — one tap, straight to the previous
  // screen. We still clean up the search UI/focus first so nothing is
  // left open underneath, then call `widget.onBack()` directly.
  // ---------------------------------------------------------------------
  void _onBackFromSearch() {
    _searchOverlayController.hide();
    _searchFocusNode.unfocus();

    setState(() {
      _searchExpanded = false;
      _suggestions = [];
    });

    widget.onBack();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isSuggesting = false;
      });

      if (_searchOverlayController.isShowing) {
        _searchOverlayController.hide();
      }

      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () async {
        if (!mounted) return;

        setState(() {
          _isSuggesting = true;
        });

        try {
          final results =
              await SearchService.getSearchSuggestions(value);

          if (!mounted) return;

          setState(() {
            _suggestions = results;
            _isSuggesting = false;
          });

          if (_suggestions.isNotEmpty &&
              !_searchOverlayController.isShowing) {
            _searchOverlayController.show();
          } else if (_suggestions.isEmpty &&
              _searchOverlayController.isShowing) {
            _searchOverlayController.hide();
          }
        } catch (_) {
          if (!mounted) return;

          setState(() {
            _suggestions = [];
            _isSuggesting = false;
          });

          if (_searchOverlayController.isShowing) {
            _searchOverlayController.hide();
          }
        }
      },
    );
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) return;

    _searchFocusNode.unfocus();
    _searchOverlayController.hide();

    setState(() {
      _searchExpanded = false;
    });

    final uri = Uri(
      path: '/products',
      queryParameters: {
        'search': trimmed,
      },
    );

    context.push(uri.toString());
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    final query = suggestion.text.trim();

    if (query.isEmpty) return;

    _searchController.text = suggestion.text;

    _searchOverlayController.hide();
    _searchFocusNode.unfocus();

    // ---------------------------------------------------------------------
    // NOTE:
    // `_searchExpanded` must be reset here too (same as
    // `_onSearchSubmitted` already does). Otherwise, after pushing the
    // results screen and pressing back to return here, this header is
    // still "stuck" showing the inline search row instead of the
    // normal title row (back / search / cart icons) — and the search
    // field can end up re-focused, popping the keyboard back up.
    // ---------------------------------------------------------------------
    setState(() {
      _searchExpanded = false;
    });

    // -------------------------------------------------------------------------
    // SHOP
    // -------------------------------------------------------------------------

    if (suggestion.isShop) {
      context.push(
        Uri(
          path: '/shops',
          queryParameters: {
            'category': 'All',
            'search': query,
          },
        ).toString(),
      );

      return;
    }

    // -------------------------------------------------------------------------
    // PRODUCT / TAG
    // -------------------------------------------------------------------------

    context.push(
      Uri(
        path: '/products',
        queryParameters: {
          'search': query,
        },
      ).toString(),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: _searchExpanded
          ? _buildSearchRow()
          : _buildTitleRow(),
    );
  }

  // ===========================================================================
  // TITLE ROW
  // ===========================================================================

  Widget _buildTitleRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _ink,
          ),
          onPressed: widget.onBack,
        ),

        Expanded(
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),

        IconButton(
          icon: const Icon(
            Icons.search,
            color: _ink,
          ),
          onPressed: _openInlineSearch,
        ),

        ValueListenableBuilder<int>(
          valueListenable: cartItemCount,
          builder: (context, count, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: _ink,
                  ),
                  onPressed: widget.onCart,
                ),

                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // SEARCH ROW
  // ===========================================================================

  Widget _buildSearchRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _ink,
          ),
          // Single tap now goes straight to the previous screen,
          // even while the inline search is expanded. See
          // `_onBackFromSearch` for why this changed from
          // `_closeInlineSearch`.
          onPressed: _onBackFromSearch,
        ),

        Expanded(
          child: CompositedTransformTarget(
            link: _searchLayerLink,
            child: OverlayPortal(
              controller: _searchOverlayController,
              overlayChildBuilder: (context) {
                return Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _searchOverlayController.hide();
                    },
                    child: Stack(
                      children: [
                        CompositedTransformFollower(
                          link: _searchLayerLink,
                          showWhenUnlinked: false,
                          offset: const Offset(0, 46),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius:
                                  BorderRadius.circular(14),
                              color: Colors.white,
                              child: SizedBox(
                                width:
                                    MediaQuery.of(context).size.width -
                                        56,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 320,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding:
                                        const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    itemCount: _suggestions.length,
                                    separatorBuilder: (_, __) =>
                                        Divider(
                                      height: 1,
                                      color:
                                          Colors.black.withOpacity(0.05),
                                    ),
                                    itemBuilder: (context, index) {
                                      final suggestion =
                                          _suggestions[index];

                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          suggestion.isShop
                                              ? Icons
                                                  .storefront_outlined
                                              : suggestion.isTag
                                                  ? Icons.sell_outlined
                                                  : Icons.search_rounded,
                                          size: 18,
                                          color: const Color(
                                            0xFF8B7355,
                                          ),
                                        ),
                                        title: Text(
                                          suggestion.text,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        trailing: suggestion.isShop
                                            ? const Text(
                                                'shop',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black38,
                                                ),
                                              )
                                            : suggestion.isTag
                                                ? const Text(
                                                    'tag',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.black38,
                                                    ),
                                                  )
                                                : null,
                                        onTap: () =>
                                            _onSuggestionTap(
                                          suggestion,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSearchSubmitted,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _ink,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,

                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.black45,
                    ),

                    suffixIcon: _isSuggesting
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : (_searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _suggestions = [];
                                  });

                                  _searchOverlayController.hide();
                                },
                              )),

                    hintText: 'Search products',

                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                    ),

                    contentPadding:
                        const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}