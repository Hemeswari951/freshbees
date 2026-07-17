import 'package:flutter/material.dart';
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
  State<EditShopInfoDialog> createState() =>
      _EditShopInfoDialogState();
}

class _EditShopInfoDialogState
    extends State<EditShopInfoDialog> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController shopNameCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController pincodeCtrl;

  // Selected categories
List<int> selectedCategoryIds = [];

// Select All
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
    text: widget.shop["shopName"] ?? "",
  );

  descriptionCtrl = TextEditingController(
    text: widget.shop["description"] ?? "",
  );

  addressCtrl = TextEditingController(
    text: widget.shop["address"] ?? "",
  );

  cityCtrl = TextEditingController(
    text: widget.shop["city"] ?? "",
  );

  stateCtrl = TextEditingController(
    text: widget.shop["state"] ?? "",
  );

  pincodeCtrl = TextEditingController(
    text: widget.shop["pincode"] ?? "",
  );

  selectedCategoryIds =
    List<String>.from(widget.shop["categories"] ?? [])
        .map((name) {
          return categories
              .firstWhere((c) => c["name"] == name)["id"] as int;
        })
        .toList();

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
  super.dispose();
}

Future<void> save() async {

  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    saving = true;
  });

  try {

    await ShopService.updateBasicInfo(

      widget.shopId,

      {

        "shopName": shopNameCtrl.text,

        "description": descriptionCtrl.text,

        "categoryIds": selectedCategoryIds,

        "address": addressCtrl.text,

        "city": cityCtrl.text,

        "state": stateCtrl.text,

        "pincode": pincodeCtrl.text,

      },

    );

    if (mounted) {

      Navigator.pop(context, true);

    }

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(
        content: Text(e.toString()),
      ),

    );

  }

  setState(() {
    saving = false;
  });
}

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

              //---------------------------------------
              // Shop Name
              //---------------------------------------

              TextFormField(

                controller: shopNameCtrl,

                decoration: const InputDecoration(
                  labelText: "Shop Name",
                  prefixIcon: Icon(Icons.store),
                ),

                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Enter shop name";
                  }
                  return null;
                },

              ),

              const SizedBox(height: 16),

              //---------------------------------------
              // Category
              //---------------------------------------

              Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey.shade300),
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

            selectAllCategories = value!;

            selectedCategoryIds.clear();

            if (selectAllCategories) {

              for (final c in categories) {

                selectedCategoryIds.add(c["id"]);

              }

            }

          });

        },
      ),

      const Divider(),

      ...categories.map((category) {

        final id = category["id"] as int;

        return CheckboxListTile(

          dense: true,

          contentPadding: EdgeInsets.zero,

          title: Text(category["name"]),

          value: selectedCategoryIds.contains(id),

          onChanged: (value) {

            setState(() {

              if (value == true) {

                selectedCategoryIds.add(id);

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

              //---------------------------------------
              // Description
              //---------------------------------------

              TextFormField(

                controller: descriptionCtrl,

                maxLines: 3,

                decoration: const InputDecoration(
                  labelText: "Description",
                  prefixIcon: Icon(Icons.description),
                ),

              ),

              const SizedBox(height: 16),

              //---------------------------------------
              // Address
              //---------------------------------------

              TextFormField(

                controller: addressCtrl,

                decoration: const InputDecoration(
                  labelText: "Address",
                  prefixIcon: Icon(Icons.location_on),
                ),

              ),

              const SizedBox(height: 16),

              //---------------------------------------
              // City
              //---------------------------------------

              TextFormField(

                controller: cityCtrl,

                decoration: const InputDecoration(
                  labelText: "City",
                  prefixIcon: Icon(Icons.location_city),
                ),

              ),

              const SizedBox(height: 16),

              //---------------------------------------
              // State
              //---------------------------------------

              TextFormField(

                controller: stateCtrl,

                decoration: const InputDecoration(
                  labelText: "State",
                  prefixIcon: Icon(Icons.map),
                ),

              ),

              const SizedBox(height: 16),

              //---------------------------------------
              // Pincode
              //---------------------------------------

              TextFormField(

                controller: pincodeCtrl,

                keyboardType: TextInputType.number,

                decoration: const InputDecoration(
                  labelText: "Pincode",
                  prefixIcon: Icon(Icons.pin_drop),
                ),

              ),

            ],

          ),

        ),

      ),

    ),

    actions: [

      OutlinedButton(

        onPressed: () {

          Navigator.pop(context);

        },

        child: const Text("Cancel"),

      ),

      ElevatedButton.icon(

        onPressed: saving
            ? null
            : save,

        icon: const Icon(Icons.save),

        label: Text(
          saving
              ? "Saving..."
              : "Save Changes",
        ),

      ),

    ],

  );

}
    }