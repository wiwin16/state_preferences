import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _favController = TextEditingController();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  // Latihan 5: karakter berbahaya (mis. <script>)
  static final RegExp _dangerousChars = RegExp(r'[<>]');

  @override
  void initState() {
    super.initState();
    // Di initState tidak boleh memakai dependOnInheritedWidgetOfExactType
    // (UserProvider.of), sehingga dipakai getInheritedWidgetOfExactType.
    final provider = context.read<UserProvider>();
    _nameController = TextEditingController(text: provider.user.name);
    _emailController = TextEditingController(text: provider.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserProvider>();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // Latihan 5b: cek karakter berbahaya pada nama
    if (_dangerousChars.hasMatch(name)) {
      _showMessage(
        'Nama mengandung karakter berbahaya (< atau >)',
        isError: true,
      );
      return;
    }

    // Latihan 5a: cek email sudah digunakan (simulasi dengan SharedPreferences)
    // Email dianggap sudah dipakai jika sama dengan email tersimpan
    // saat pengguna belum login (pendaftaran baru).
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email') ?? '';
    final emailUsed =
        !provider.user.isLoggedIn &&
        savedEmail.isNotEmpty &&
        savedEmail.toLowerCase() == email.toLowerCase();

    if (!mounted) return;
    if (emailUsed) {
      _showMessage('Email sudah digunakan', isError: true);
      return;
    }

    final updatedUser = provider.user.copyWith(
      name: name,
      email: email,
      isLoggedIn: true,
    );
    provider.updateUser(updatedUser);

    _showMessage('Profil berhasil disimpan');
  }

  void _logout() {
    final provider = context.read<UserProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.logout();
              Navigator.pop(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Latihan 3: tambah favorit
  void _addFavorite() {
    final provider = context.read<UserProvider>();
    final item = _favController.text.trim();
    if (item.isEmpty) return;

    if (_dangerousChars.hasMatch(item)) {
      _showMessage('Favorit mengandung karakter berbahaya', isError: true);
      return;
    }
    if (provider.favorites.any((f) => f.toLowerCase() == item.toLowerCase())) {
      _showMessage('Item sudah ada di daftar favorit', isError: true);
      return;
    }

    provider.addFavorite(item);
    _favController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Nama',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Latihan 3: daftar favorit
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daftar Favorit',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _favController,
                                      decoration: const InputDecoration(
                                        hintText: 'Tambah favorit (mis. hobi)',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onFieldSubmitted: (_) => _addFavorite(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    onPressed: _addFavorite,
                                    icon: const Icon(Icons.add),
                                    tooltip: 'Tambah',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (provider.favorites.isEmpty)
                                const Text(
                                  'Belum ada favorit',
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                ...provider.favorites.map(
                                  (item) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.favorite,
                                      color: Colors.pink,
                                    ),
                                    title: Text(item),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Hapus',
                                      onPressed: () =>
                                          provider.removeFavorite(item),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Card(
                        color: const Color.fromRGBO(255, 193, 7, 0.15),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.amber[800]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Catatan Keamanan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Data disimpan di SharedPreferences (plaintext). '
                                'Jangan simpan password atau data sensitif di sini. '
                                'Gunakan secure storage untuk data sensitif.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
