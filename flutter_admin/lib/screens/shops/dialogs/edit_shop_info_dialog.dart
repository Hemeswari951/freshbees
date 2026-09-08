import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/shop_service.dart';

class EditShopInfoDialog extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic> shop;

  const EditShopInfoDialog({
    super.key,
    required this.shopId,
    required this.shop,
  });

  @override
  State<EditShopInfoDialog> createState() => _EditShopInfoDialogState();
}

class _EditShopInfoDialogState extends State<EditShopInfoDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController shopNameCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController pincodeCtrl;
  late TextEditingController locationUrlCtrl;

  // ── Categories ────────────────────────────────────────────────────────────

  List<int> selectedCategoryIds = [];

  bool selectAllCategories = false;

  final List<Map<String, dynamic>> categories = const [
    {"id": 1, "name": "Men"},
    {"id": 2, "name": "Women"},
    {"id": 3, "name": "Kids"},
    {"id": 4, "name": "Beauty"},
  ];

  bool saving = false;

  @override
  void initState() {
    super.initState();

    shopNameCtrl = TextEditingController(
      text: widget.shop["shopName"]?.toString() ?? "",
    );

    descriptionCtrl = TextEditingController(
      text: widget.shop["description"]?.toString() ?? "",
    );

    addressCtrl = TextEditingController(
      text: widget.shop["address"]?.toString() ?? "",
    );

    cityCtrl = TextEditingController(
      text: widget.shop["city"]?.toString() ?? "",
    );

    stateCtrl = TextEditingController(
      text: widget.shop["state"]?.toString() ?? "",
    );

    pincodeCtrl = TextEditingController(
      text: widget.shop["pincode"]?.toString() ?? "",
    );

    // Supports both API camelCase and DB snake_case response.
    locationUrlCtrl = TextEditingController(
      text: widget.shop["locationUrl"]?.toString() ??
          widget.shop["location_url"]?.toString() ??
          "",
    );

    // Categories can come as category names.
    final rawCategories = widget.shop["categories"];

    if (rawCategories is List) {
      selectedCategoryIds = rawCategories
          .map((name) {
            final categoryName = name.toString();

            final match = categories.where(
              (c) => c["name"].toString() == categoryName,
            );

            if (match.isEmpty) return null;

            return match.first["id"] as int;
          })
          .whereType<int>()
          .toList();
    }

    selectAllCategories =
        selectedCategoryIds.length == categories.length;
  }

  @override
  void dispose() {
    shopNameCtrl.dispose();
    descriptionCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pincodeCtrl.dispose();
    locationUrlCtrl.dispose();

    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one category"),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await ShopService.updateBasicInfo(
        widget.shopId,
        {
          "shopName": shopNameCtrl.text.trim(),
          "description": descriptionCtrl.text.trim(),
          "categoryIds": selectedCategoryIds,
          "address": addressCtrl.text.trim(),
          "city": cityCtrl.text.trim(),
          "state": stateCtrl.text.trim(),
          "pincode": pincodeCtrl.text.trim(),
          "locationUrl": locationUrlCtrl.text.trim(),
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: const Color(0xFFA32D2D),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Text(
        "Edit Shop Information",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─────────────────────────────────────────────────────────
                // Shop Name
                // ─────────────────────────────────────────────────────────

                TextFormField(
                  controller: shopNameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Shop Name",
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Enter shop name";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────────────────────────
                // Categories
                // ─────────────────────────────────────────────────────────

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Categories",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Select All"),
                        value: selectAllCategories,
                        onChanged: (value) {
                          setState(() {
                            selectAllCategories = value ?? false;

                            selectedCategoryIds.clear();

                            if (selectAllCategories) {
                              for (final category in categories) {
                                selectedCategoryIds.add(
                                  category["id"] as int,
                                );
                              }
                            }
                          });
                        },
                      ),

                      const Divider(),

                      ...categories.map((category) {
                        final id = category["id"] as int;
                        final name = category["name"].toString();

                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(name),
                          value: selectedCategoryIds.contains(id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedCategoryIds.contains(id)) {
                                  selectedCategoryIds.add(id);
                                }
                              } else {
                                selectedCategoryIds.remove(id);
                              }

                              selectAllCategories =
                                  selectedCategoryIds.length ==
                                      categories.length;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────────────────────────
                // Description
                // ─────────────────────────────────────────────────────────

                TextFormField(
                  controller: descriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Enter description";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────────────────────────
                // Address
                // ─────────────────────────────────────────────────────────

                TextFormField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Enter address";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────────────────────────
                // City
                // ─────────────────────────────────────────────────────────

                TextFormField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: "City",
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Enter city";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────────────────────────
                // State
                // ─────────────────────────────────────────────────────────

                TextFormField(
                  controller: stateCtrl,
                  decoration: const InputDecoration(
                    labelText: "State",
                    prefixIcon: Icon(Icons.map),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Enter state";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────────────────────────
                // Pincode
                // ─────────────────────────────────────────────────────────

                TextFormField(
                  controller: pincodeCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: "Pincode",
                    prefixIcon: Icon(Icons.pin_drop),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? "";

                    if (value.isEmpty) {
                      return "Enter pincode";
                    }

                    if (value.length != 6) {
                      return "Pincode must be 6 digits";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ─────────────────────────────────────────────────────────
                // Location URL
                // ─────────────────────────────────────────────────────────

                TextFormField(
                  controller: locationUrlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: "Google Maps Location URL",
                    hintText: "https://maps.google.com/...",
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? "";

                    if (value.isEmpty) {
                      return "Enter Google Maps location URL";
                    }

                    final uri = Uri.tryParse(value);

                    if (uri == null ||
                        (uri.scheme != "http" &&
                            uri.scheme != "https")) {
                      return "Enter a valid URL";
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // ─────────────────────────────────────────────────────────────────
        // Cancel
        // ─────────────────────────────────────────────────────────────────

        OutlinedButton(
          onPressed: saving
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: const Text("Cancel"),
        ),

        // ─────────────────────────────────────────────────────────────────
        // Save
        // ─────────────────────────────────────────────────────────────────

        ElevatedButton.icon(
          onPressed: saving ? null : save,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(
            saving ? "Saving..." : "Save Changes",
          ),
        ),
      ],
    );
  }
}