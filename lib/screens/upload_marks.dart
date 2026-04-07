import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadMarks extends StatefulWidget {
  const UploadMarks({super.key});

  @override
  State<UploadMarks> createState() => _UploadMarksState();
}

class _UploadMarksState extends State<UploadMarks> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  List<Map<String, dynamic>> _teacherSubjects = [];
  Map<String, dynamic>? _selectedSubject;
  List<Map<String, dynamic>> _students = [];

  // Controllers mapped by student ID
  final Map<String, TextEditingController> _internalControllers = {};
  final Map<String, TextEditingController> _externalControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final subData = await Supabase.instance.client
          .from('subjects')
          .select('id, code, name, semester')
          .eq('teacher_id', user.id);
          
      if (mounted) {
        setState(() {
          _teacherSubjects = subData.cast<Map<String, dynamic>>();
        });
      }
      
      if (_teacherSubjects.isNotEmpty) {
        _selectedSubject = _teacherSubjects.first;
        await _fetchStudentsForSubject(_selectedSubject!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudentsForSubject(Map<String, dynamic> subject) async {
    setState(() {
      _isLoading = true;
      _students = [];
    });

    try {
      // Fetch students for this semester
      final studentData = await Supabase.instance.client
          .from('users')
          .select('id, name, batch')
          .eq('role', 'student')
          .eq('is_admin', false)
          .eq('semester', subject['semester']);

      // Fetch existing marks if any
      final existingMarksData = await Supabase.instance.client
          .from('marks')
          .select('student_id, internal, external')
          .eq('subject_id', subject['id']);

      final existingMarks = {
        for (var m in existingMarksData) m['student_id'] as String: m
      };

      for (var st in studentData) {
        String sId = st['id'];
        _internalControllers[sId] = TextEditingController(
          text: existingMarks[sId]?['internal']?.toString() ?? '',
        );
        _externalControllers[sId] = TextEditingController(
          text: existingMarks[sId]?['external']?.toString() ?? '',
        );
      }

      if (mounted) {
        setState(() {
          _students = studentData.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMarks() async {
    if (_selectedSubject == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final subjectId = _selectedSubject!['id'];
      final List<Map<String, dynamic>> upsertData = [];

      for (var st in _students) {
        String sId = st['id'];
        int internal = int.tryParse(_internalControllers[sId]?.text.trim() ?? '0') ?? 0;
        int external = int.tryParse(_externalControllers[sId]?.text.trim() ?? '0') ?? 0;
        
        // Boundaries
        if (internal > 30) internal = 30;
        if (external > 70) external = 70;
        int total = internal + external;

        upsertData.add({
          'student_id': sId,
          'subject_id': subjectId,
          'internal': internal,
          'external': external,
          'total': total,
        });
      }

      if (upsertData.isNotEmpty) {
        await Supabase.instance.client
            .from('marks')
            .upsert(upsertData, onConflict: 'student_id,subject_id');
            
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client.from('teacher_activity').insert({
            'teacher_id': user.id,
            'action': 'Uploaded marks for',
            'target': '${upsertData.length} students in ${_selectedSubject!['code']}',
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks successfully saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving marks: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          title: const Text('Upload Marks'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_teacherSubjects.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: const InputDecoration(labelText: 'Select Subject', border: OutlineInputBorder()),
                        value: _selectedSubject,
                        items: _teacherSubjects.map((subject) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: subject,
                            child: Text('${subject['code']} - ${subject['name']}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSubject = val);
                            _fetchStudentsForSubject(val);
                          }
                        },
                      ),
                    ),
                  
                  if (_students.isEmpty && !_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No students found.'),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _students.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final st = _students[index];
                          final sId = st['id'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(st['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(st['batch'] ?? 'Batch', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _internalControllers[sId],
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            TextInputFormatter.withFunction((old, newVal) {
                                              final n = int.tryParse(newVal.text);
                                              if (n != null && n > 30) {
                                                return old;
                                              }
                                              return newVal;
                                            }),
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'Internal /30',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (v) => setState((){}),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _externalControllers[sId],
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            TextInputFormatter.withFunction((old, newVal) {
                                              final n = int.tryParse(newVal.text);
                                              if (n != null && n > 70) {
                                                return old;
                                              }
                                              return newVal;
                                            }),
                                          ],
                                          decoration: const InputDecoration(
                                            labelText: 'External /70',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (v) => setState((){}),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        children: [
                                          const Text('Total', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Text(
                                              '${(int.tryParse(_internalControllers[sId]?.text ?? '0') ?? 0) + (int.tryParse(_externalControllers[sId]?.text ?? '0') ?? 0)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
        bottomNavigationBar: _students.isNotEmpty && !_isLoading
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMarks,
                  icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                  label: const Text('SAVE MARKS'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
