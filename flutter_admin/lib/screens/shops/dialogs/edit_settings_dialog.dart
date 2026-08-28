import 'package:flutter/material.dart';

import '../../../services/shop_service.dart';

class EditSettingsDialog extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic> shop;

  const EditSettingsDialog({
    super.key,
    required this.shopId,
    required this.shop,
  });

  @override
  State<EditSettingsDialog> createState() =>
      _EditSettingsDialogState();
}

class _EditSettingsDialogState
    extends State<EditSettingsDialog> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController commissionCtrl;

  bool activateShop = true;
  bool allowProductUploads = true;
  bool enablePayoutRequests = false;

  bool saving = false;

  @override
  void initState() {

    super.initState();

    final settings = widget.shop["settings"] ?? {};

    commissionCtrl = TextEditingController(
      text: "${settings["commissionRate"] ?? 10}",
    );

    activateShop =
        settings["activateImmediately"] ?? true;

    allowProductUploads =
        settings["allowProductUploads"] ?? true;

    enablePayoutRequests =
        settings["enablePayoutRequests"] ?? false;
  }

  @override
  void dispose() {
    commissionCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
    });

    try {

      await ShopService.updateSettings(

        widget.shopId,

        {

          "commissionRate":
              double.parse(commissionCtrl.text),

          "activateImmediately":
              activateShop,

          "allowProductUploads":
              allowProductUploads,

          "enablePayoutRequests":
              enablePayoutRequests,

        },

      );

      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {

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
        "Edit Shop Settings",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      content: SizedBox(

        width: 450,

        child: Form(

          key: _formKey,

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              TextFormField(

                controller: commissionCtrl,

                keyboardType:
                    TextInputType.number,

                decoration: const InputDecoration(

                  labelText: "Commission Rate (%)",

                  prefixIcon:
                      Icon(Icons.percent),

                ),

                validator: (value){

                  if(value==null ||
                      value.isEmpty){

                    return "Enter commission";

                  }

                  return null;

                },

              ),

              const SizedBox(height:20),

              SwitchListTile(

                value: activateShop,

                title: const Text(
                  "Activate Shop",
                ),

                onChanged: (value){

                  setState(() {

                    activateShop=value;

                  });

                },

              ),

              SwitchListTile(

                value: allowProductUploads,

                title: const Text(
                  "Allow Product Uploads",
                ),

                onChanged: (value){

                  setState(() {

                    allowProductUploads=value;

                  });

                },

              ),

              SwitchListTile(

                value: enablePayoutRequests,

                title: const Text(
                  "Enable Payout Requests",
                ),

                onChanged: (value){

                  setState(() {

                    enablePayoutRequests=value;

                  });

                },

              ),

            ],

          ),

        ),

      ),

      actions: [

        OutlinedButton(

          onPressed: (){

            Navigator.pop(context);

          },

          child: const Text("Cancel"),

        ),

        ElevatedButton.icon(

          onPressed:
              saving ? null : save,

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