import 'package:flutter/material.dart';
import '../../services/tryon_profile_service.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';
import '../../models/product_model.dart';
import '../../models/tryon_profile_model.dart';



class TryOnProfileSelectionScreen extends StatefulWidget {
  final ProductModel? selectedProduct;

  const TryOnProfileSelectionScreen({super.key, this.selectedProduct});

  @override
  State<TryOnProfileSelectionScreen> createState() =>
      _TryOnProfileSelectionScreenState();
}

class _TryOnProfileSelectionScreenState
    extends State<TryOnProfileSelectionScreen> {

  bool _loading = true;
  String? _errorMessage;

  List<TryOnProfile> _profiles = [];

ProfileModel? _customerProfile;

// Main user's Try-On Profile
TryOnProfile? _mainTryOnProfile;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
  try {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final profiles =
        await TryOnProfileService.getProfiles();

    final customerProfile =
        await ProfileService.getProfile();

    final mainTryOnProfile =
        await TryOnProfileService.getMainProfile();

    // Remove the main/self Try-On profile from
    // the additional profiles list.
    //
    // It is already represented by the "Me" card.
    final additionalProfiles = profiles.where((profile) {
      return profile.profileId != mainTryOnProfile.profileId;
    }).toList();

    if (!mounted) return;

    setState(() {
      _customerProfile = customerProfile;

      // Keep this separately because it may be needed
      // later in the Try-On flow.
      _mainTryOnProfile = mainTryOnProfile;

      // Only show additional people here.
      _profiles = additionalProfiles;

      _loading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _loading = false;
      _errorMessage = e.toString();
    });
  }
}

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F4EE),

        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F4EE),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
            ),
            onPressed: () {
      context.go('/home');
    },
          ),
          title: const Text(
            'Select Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),

        body: _buildBody(),
      );
    }

    Widget _buildBody() {

      if (_loading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (_errorMessage != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.error_outline,
                  size: 45,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Unable to load your profiles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loadProfiles,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadProfiles,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            const Text(
              'Who are you trying this for?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Select a saved profile or add someone new.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 28),

            if (_customerProfile != null)
    _customerProfileCard(_customerProfile!),


            ..._profiles.map(
              (profile) => _profileCard(profile),
            ),

            const SizedBox(height: 16),

            _addPersonCard(),
          ],
        ),
      );
    }

Widget _customerProfileCard(ProfileModel profile) {
  return Card(
    margin: const EdgeInsets.only(bottom: 14),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(
        color: Color(0xFFE2D8CA),
      ),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),

      leading: CircleAvatar(
        radius: 27,
        backgroundColor: const Color(0xFFE8DFD1),
        backgroundImage:
            profile.profileImage != null &&
                    profile.profileImage!.isNotEmpty
                ? NetworkImage(
                    ApiService.imageUrl(
                      profile.profileImage,
                    ),
                  )
                : null,
        child:
            profile.profileImage == null ||
                    profile.profileImage!.isEmpty
                ? const Icon(
                    Icons.person_outline,
                    color: Colors.black54,
                  )
                : null,
      ),

      title: Row(
        children: [
          Text(
            profile.fullName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8DFD1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Me',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      subtitle: const Text(
        'My Profile',
        style: TextStyle(
          color: Colors.black54,
        ),
      ),

      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),

      onTap: () {
  context.push(
    '/virtual-tryon/photo',
    extra: {
      'profile': _mainTryOnProfile,
      'customerProfile': profile,
      'product': widget.selectedProduct,
    },
  );
},
    ),
  );
}

  Widget _profileCard(TryOnProfile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE2D8CA),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        leading: CircleAvatar(
          radius: 27,
          backgroundColor: const Color(0xFFE8DFD1),
          backgroundImage:
              profile.photoUrl != null &&
                      profile.photoUrl!.isNotEmpty
                  ? NetworkImage(
  ApiService.imageUrl(profile.photoUrl),
)
                  : null,
          child:
              profile.photoUrl == null ||
                      profile.photoUrl!.isEmpty
                  ? const Icon(
                      Icons.person_outline,
                      color: Colors.black54,
                    )
                  : null,
        ),

        title: Text(
          profile.profileName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(
          profile.relationship,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),

        onTap: () {
  context.push(
    '/virtual-tryon/photo',
    extra: {
      'profile': profile,
      'product': widget.selectedProduct,
    },
  );
},
      ),
    );
  }

  Widget _addPersonCard()  {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
  final added =  context.push<bool>(
  '/virtual-tryon/add-profile',
);

if (added == true) {
   _loadProfiles();
}
},
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFB8A48D),
          ),
        ),
        child: const Row(
          children: [

            CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFE8DFD1),
              child: Icon(
                Icons.add,
                color: Colors.black87,
              ),
            ),

            SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Person',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create a profile for someone else',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}