import 'package:flutter/material.dart';

import '../../../services/shop_service.dart';
// import '../../../widgets/t_colors.dart';

class EditOwnerDialog extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic> shop;

  const EditOwnerDialog({
    super.key,
    required this.shopId,
    required this.shop,
  });

  @override
  State<EditOwnerDialog> createState() =>
      _EditOwnerDialogState();
}

class _EditOwnerDialogState
    extends State<EditOwnerDialog> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController ownerNameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    ownerNameCtrl = TextEditingController(
      text: widget.shop["ownerName"] ?? "",
    );

    emailCtrl = TextEditingController(
      text: widget.shop["ownerEmail"] ?? "",
    );

    phoneCtrl = TextEditingController(
      text: widget.shop["ownerPhone"] ?? "",
    );
  }

  @override
  void dispose() {
    ownerNameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
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

      await ShopService.updateOwnerInfo(

        widget.shopId,

        {

          "ownerName": ownerNameCtrl.text.trim(),

          "ownerEmail": emailCtrl.text.trim(),

          "ownerPhone": phoneCtrl.text.trim(),

        },

      );

      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            content: Text(
              e.toString().replaceFirst(
                "Exception: ",
                "",
              ),
            ),
          ),

        );

      }

    }

    if (mounted) {

      setState(() {

        saving = false;

      });

    }

  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      title: const Text(
        "Edit Owner Information",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      content: SizedBox(

        width: 450,

        child: SingleChildScrollView(

          child: Form(

            key: _formKey,

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                //-----------------------------------
                // OWNER NAME
                //-----------------------------------

                TextFormField(

                  controller: ownerNameCtrl,

                  decoration: const InputDecoration(

                    labelText: "Owner Name",

                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),

                  ),

                  validator: (value) {

                    if (value == null ||
                        value.trim().isEmpty) {

                      return "Enter owner name";

                    }

                    return null;

                  },

                ),

                const SizedBox(height: 18),

                //-----------------------------------
                // EMAIL
                //-----------------------------------

                TextFormField(

                  controller: emailCtrl,

                  keyboardType:
                      TextInputType.emailAddress,

                  decoration: const InputDecoration(

                    labelText: "Email",

                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),

                  ),

                  validator: (value) {

                    if (value == null ||
                        value.trim().isEmpty) {

                      return "Enter email";

                    }

                    if (!value.contains("@")) {

                      return "Invalid email";

                    }

                    return null;

                  },

                ),

                const SizedBox(height: 18),

                //-----------------------------------
                // PHONE
                //-----------------------------------

                TextFormField(

                  controller: phoneCtrl,

                  keyboardType:
                      TextInputType.phone,

                  decoration: const InputDecoration(

                    labelText: "Phone Number",

                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),

                  ),

                  validator: (value) {

                    if (value == null ||
                        value.trim().isEmpty) {

                      return "Enter phone number";

                    }

                    if (value.length != 10) {

                      return "Phone must be 10 digits";

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

        OutlinedButton(

          onPressed: () {

            Navigator.pop(context);

          },

          child: const Text(
            "Cancel",
          ),

        ),

        ElevatedButton.icon(

          onPressed: saving
              ? null
              : save,

          icon: const Icon(
            Icons.save,
          ),

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