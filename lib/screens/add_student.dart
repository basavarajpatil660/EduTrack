import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddStudent extends StatefulWidget {
  const AddStudent({super.key});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _batchController = TextEditingController();
  final _semesterController = TextEditingController();
  
  bool _isLoading = false;
  final String _defaultPassword = 'EduTrack@123';

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      final response = await supabase.functions.invoke(
        'create-student',
        headers: {
          'Authorization': 'Bearer ${session!.accessToken}',
          'Content-Type': 'application/json',
        },
        body: {
          'email': _emailController.text.trim(),
          'password': _defaultPassword,
          'name': _nameController.text.trim(),
          'roll_number': _rollNumberController.text.trim(),
          'batch': _batchController.text.trim(),
          'semester': int.parse(_semesterController.text.trim()),
        },
      );

      if (response.data['success'] == true) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Student Registered'),
              content: Text(
                'Student successfully registered.\n\n'
                'Email: ${_emailController.text.trim()}\n'
                'Password: $_defaultPassword',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // return to previous screen
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        final errorMsg = response.data['error'] ?? 'Unknown error from server.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $errorMsg')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add student: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollNumberController.dispose();
    _batchController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) return true;
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add New Student'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (!val.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _rollNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Roll Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _batchController,
                        decoration: const InputDecoration(
                          labelText: 'Batch (e.g. 2024)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _semesterController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Semester (1-8)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if (int.tryParse(val) == null) return 'Must be number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A default password "$_defaultPassword" will be automatically assigned.',
                          style: TextStyle(color: Colors.amber[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('REGISTER STUDENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
