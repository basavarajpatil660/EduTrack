import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_nav.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserRole role;

  const ProfileScreen({super.key, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in.';
        });
        return;
      }

      final data = await Supabase.instance.client
          .from('users')
          .select('name, email, role, batch, semester')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile data.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    // The main StreamBuilder in AuthGate will handle returning to login screen automatically
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) return true;
        return false;
      },
      child: Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.9),
          elevation: 0,
          scrolledUnderElevation: 4,
          shadowColor: Colors.black.withOpacity(0.05),
          centerTitle: true,
          title: Text(
            'Profile',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: _buildBody(context),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, // Assuming 3 is Profile
        role: widget.role,
      ),
    ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchProfile, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_userData == null) {
      return const Center(child: Text('No profile data found.'));
    }

    final name = _userData!['name'] ?? 'Unknown User';
    final email = _userData!['email'] ?? 'No email';
    final role = _userData!['role'] ?? 'student';
    final batchName = _userData!['batch'];
    final semester = _userData!['semester'];

    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow(context, 'Role', role.toString().toUpperCase()),
          const Divider(),
          if (batchName != null) ...[
            _buildInfoRow(context, 'Batch', batchName),
            const Divider(),
          ],
          if (semester != null) ...[
            _buildInfoRow(context, 'Semester', semester.toString()),
            const Divider(),
          ],
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('LOGOUT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
