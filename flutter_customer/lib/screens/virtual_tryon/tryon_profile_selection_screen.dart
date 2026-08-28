import 'package:flutter/material.dart';
import '../../services/tryon_profile_service.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';



class TryOnProfileSelectionScreen extends StatefulWidget {
  const TryOnProfileSelectionScreen({super.key});

  @override
  State<TryOnProfileSelectionScreen> createState() =>
      _TryOnProfileSelectionScreenState();
}

class _TryOnProfileSelectionScreenState
    extends State<TryOnProfileSelectionScreen> {

  bool _loading = true;
  String? _errorMessage;

  List<TryOnProfile> _profiles = [];

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

      if (!mounted) return;

      setState(() {
        _profiles = profiles;
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

          ..._profiles.map(
            (profile) => _profileCard(profile),
          ),

          const SizedBox(height: 16),

          _addPersonCard(),
        ],
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
    extra: profile,
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