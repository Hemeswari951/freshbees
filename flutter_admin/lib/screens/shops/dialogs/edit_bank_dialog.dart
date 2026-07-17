import 'package:flutter/material.dart';

import '../../../services/shop_service.dart';
// import '../../../widgets/t_colors.dart';

class EditBankDialog extends StatefulWidget {
  final int shopId;
  final Map<String, dynamic> shop;

  const EditBankDialog({
    super.key,
    required this.shopId,
    required this.shop,
  });

  @override
  State<EditBankDialog> createState() => _EditBankDialogState();
}

class _EditBankDialogState extends State<EditBankDialog> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController accountHolderCtrl;
  late TextEditingController accountNumberCtrl;
  late TextEditingController bankNameCtrl;
  late TextEditingController ifscCtrl;
  late TextEditingController gstCtrl;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final bank = widget.shop["bankDetails"] ?? {};

    accountHolderCtrl = TextEditingController(
      text: bank["accountHolderName"] ?? "",
    );

    accountNumberCtrl = TextEditingController(
      text: bank["accountNumber"] ?? "",
    );

    bankNameCtrl = TextEditingController(
      text: bank["bankName"] ?? "",
    );

    ifscCtrl = TextEditingController(
      text: bank["ifscCode"] ?? "",
    );

    gstCtrl = TextEditingController(
      text: bank["gstNumber"] ?? "",
    );
  }

  @override
  void dispose() {
    accountHolderCtrl.dispose();
    accountNumberCtrl.dispose();
    bankNameCtrl.dispose();
    ifscCtrl.dispose();
    gstCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
    });

    try {

      await ShopService.updateBankInfo(

        widget.shopId,

        {

          "accountHolderName": accountHolderCtrl.text.trim(),

          "accountNumber": accountNumberCtrl.text.trim(),

          "bankName": bankNameCtrl.text.trim(),

          "ifscCode": ifscCtrl.text.trim(),

          "gstNumber": gstCtrl.text.trim(),

        },

      );

      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
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
        "Edit Bank Details",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      content: SizedBox(

        width: 480,

        child: SingleChildScrollView(

          child: Form(

            key: _formKey,

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                TextFormField(
                  controller: accountHolderCtrl,
                  decoration: const InputDecoration(
                    labelText: "Account Holder Name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: accountNumberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Account Number",
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: bankNameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Bank Name",
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: ifscCtrl,
                  decoration: const InputDecoration(
                    labelText: "IFSC Code",
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: gstCtrl,
                  decoration: const InputDecoration(
                    labelText: "GST Number",
                    prefixIcon: Icon(Icons.receipt_long_outlined),
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

          onPressed: saving ? null : save,

          icon: const Icon(Icons.save),

          label: Text(
            saving ? "Saving..." : "Save Changes",
          ),

        ),

      ],

    );

  }

}