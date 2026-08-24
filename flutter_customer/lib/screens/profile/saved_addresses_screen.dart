import 'package:flutter/material.dart';
import '../../services/address_service.dart';
import '../address/add_address_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  static const Color _bg = Color(0xFFF6F6F7);
  static const Color _surface = Colors.white;
  static const Color _ink = Color(0xFF1A1A1D);
  static const Color _muted = Color(0xFF8A8A8E);
  static const Color _line = Color(0xFFE7E7E9);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _accentSoft = Color(0xFFF2ECE4);

  bool _loading = true;
  String? _error;

  List<AddressModel> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // ------------------------------------------------------------
  // LOAD SAVED ADDRESSES
  // ------------------------------------------------------------

  Future<void> _loadAddresses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final addresses = await AddressService.getAddresses();

      if (!mounted) return;

      setState(() {
        _addresses = addresses;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // ADD NEW ADDRESS
  // ------------------------------------------------------------

  Future<void> _addNewAddress() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddAddressScreen(),
      ),
    );

    if (added == true) {
      _loadAddresses();
    }
  }

  // ------------------------------------------------------------
  // SET DEFAULT ADDRESS
  // ------------------------------------------------------------

  Future<void> _setDefault(AddressModel address) async {
    try {
      await AddressService.setDefault(address.addressId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default address updated'),
        ),
      );

      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // DELETE ADDRESS
  // ------------------------------------------------------------

  Future<void> _deleteAddress(AddressModel address) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Address'),
          content: const Text(
            'Are you sure you want to delete this saved address?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'DELETE',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await AddressService.deleteAddress(address.addressId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted'),
        ),
      );

      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved Addresses',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _addresses.isEmpty
                    ? 'Manage your delivery addresses'
                    : '${_addresses.length} saved address${_addresses.length == 1 ? '' : 'es'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        ElevatedButton.icon(
          onPressed: _addNewAddress,
          icon: const Icon(
            Icons.add,
            size: 18,
          ),
          label: const Text(
            'ADD ADDRESS',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BODY
  // ------------------------------------------------------------

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_addresses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAddresses,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          return _buildAddressCard(_addresses[index]);
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // ERROR
  // ------------------------------------------------------------

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _loadAddresses,
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: _accentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 36,
              color: _accent,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No saved addresses',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add an address to make checkout faster.',
            style: TextStyle(
              fontSize: 13,
              color: _muted,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _addNewAddress,
            icon: const Icon(Icons.add),
            label: const Text('ADD NEW ADDRESS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: const BorderSide(
                color: _accent,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ADDRESS CARD
  // ------------------------------------------------------------

  Widget _buildAddressCard(AddressModel address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: address.isDefault ? _accent : _line,
          width: address.isDefault ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW
          Row(
            children: [
              _addressIcon(address.addressType),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  address.addressType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),

              if (address.isDefault)
                _defaultBadge(),
            ],
          ),

          const SizedBox(height: 16),

          // NAME
          Text(
            address.fullName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),

          const SizedBox(height: 5),

          // PHONE
          Text(
            address.phone,
            style: const TextStyle(
              fontSize: 13,
              color: _muted,
            ),
          ),

          const SizedBox(height: 10),

          // ADDRESS
          Text(
            address.oneLine,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _ink,
            ),
          ),

          const SizedBox(height: 16),

          const Divider(
            height: 1,
            color: _line,
          ),

          const SizedBox(height: 10),

          // ACTIONS
          Row(
            children: [
              if (!address.isDefault)
                TextButton.icon(
                  onPressed: () => _setDefault(address),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 17,
                  ),
                  label: const Text(
                    'Set as Default',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _accent,
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Default address',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const Spacer(),

              TextButton.icon(
                onPressed: () => _deleteAddress(address),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 17,
                ),
                label: const Text(
                  'Delete',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ADDRESS ICON
  // ------------------------------------------------------------

  Widget _addressIcon(String type) {
    IconData icon;

    switch (type.toLowerCase()) {
      case 'work':
        icon = Icons.work_outline;
        break;

      case 'other':
        icon = Icons.location_on_outlined;
        break;

      default:
        icon = Icons.home_outlined;
    }

    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: _accentSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: _accent,
      ),
    );
  }

  // ------------------------------------------------------------
  // DEFAULT BADGE
  // ------------------------------------------------------------

  Widget _defaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'DEFAULT',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}