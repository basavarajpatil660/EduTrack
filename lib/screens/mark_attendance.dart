import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({super.key});

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

class _Student {
  final String id;
  final String initials;
  final String name;
  final String studentCode;
  final Color avatarColor;
  final Color onAvatarColor;
  bool? isPresent;

  _Student({
    required this.id,
    required this.initials,
    required this.name,
    required this.studentCode,
    required this.avatarColor,
    required this.onAvatarColor,
    this.isPresent,
  });
}

class _MarkAttendanceState extends State<MarkAttendance> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  List<_Student> _allStudents = [];
  List<Map<String, dynamic>> _teacherSubjects = [];
  Map<String, dynamic>? _selectedSubject;
  DateTime _selectedDate = DateTime.now();

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
          
      _teacherSubjects = subData.cast<Map<String, dynamic>>();
      
      if (_teacherSubjects.isNotEmpty) {
        _selectedSubject = _teacherSubjects.first;
        await _fetchStudentsForSubject(_selectedSubject!);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have no assigned subjects.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: $e')),
        );
      }
    }
  }

  Future<void> _fetchStudentsForSubject(Map<String, dynamic> subject) async {
    setState(() {
      _isLoading = true;
      _allStudents = [];
    });

    try {
      // Fetch students for this semester, excluding admins
      final studentData = await Supabase.instance.client
          .from('users')
          .select('id, name, batch')
          .eq('role', 'student')
          .eq('is_admin', false)
          .eq('semester', subject['semester']);

      // Pre-fill today's existing attendance
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final existingAttendance = await Supabase.instance.client
          .from('attendance')
          .select('student_id, status')
          .eq('subject_id', subject['id'])
          .eq('date', dateStr);

      final existingMap = {
        for (var a in existingAttendance)
          a['student_id'] as String: a['status'] as String
      };

      List<_Student> loadedStudents = [];
      final List<Color> colors = [
        const Color(0xFFD4E3FF), const Color(0xFFD7E2FF),
        const Color(0xFFD6E3FF), const Color(0xFFAFC8F0),
        const Color(0xFFACC7FF), const Color(0xFFA9C7FF)
      ];
      final List<Color> onColors = [
        const Color(0xFF001C3A), const Color(0xFF001A40),
        const Color(0xFF001B3D), const Color(0xFF2F486A),
        const Color(0xFF2A4678), const Color(0xFF00468C)
      ];

      for (int i = 0; i < studentData.length; i++) {
        final st = studentData[i];
        final name = st['name'] as String? ?? 'Unknown';
        final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
        final studentId = st['id'] as String;
        bool? preFilledPresent;
        if (existingMap.containsKey(studentId)) {
          preFilledPresent = existingMap[studentId] == 'present';
        }
        loadedStudents.add(_Student(
          id: studentId,
          initials: initials,
          name: name,
          studentCode: st['batch'] as String? ?? 'Student',
          avatarColor: colors[i % colors.length],
          onAvatarColor: onColors[i % onColors.length],
          isPresent: preFilledPresent,
        ));
      }

      if (mounted) {
        setState(() {
          _allStudents = loadedStudents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_selectedSubject == null) return;
    
    final markedStudents = _allStudents.where((s) => s.isPresent != null).toList();
    if (markedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No attendance marked yet.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final subjectId = _selectedSubject!['id'];

      final updates = markedStudents.map((s) => {
        'student_id': s.id,
        'subject_id': subjectId,
        'date': dateStr,
        'status': s.isPresent == true ? 'present' : 'absent',
        'teacher_id': user.id,
      }).toList();

      await Supabase.instance.client
          .from('attendance')
          .upsert(updates, onConflict: 'student_id,subject_id,date');
          
      await Supabase.instance.client.from('teacher_activity').insert({
        'teacher_id': user.id,
        'action': 'Marked attendance on $dateStr for',
        'target': '${markedStudents.length} students in ${_selectedSubject!['code']}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance successfully submitted!')),
        );
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving attendance. Ensure DB has teacher_id in attendance table if strict. $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  int get markedCount => _allStudents.where((s) => s.isPresent != null).length;
  int get presentCount => _allStudents.where((s) => s.isPresent == true).length;
  int get absentCount => _allStudents.where((s) => s.isPresent == false).length;

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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.primary),
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
            title: Text(
              'Mark Attendance',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Setup Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Dropdown
                        Text(
                          'SELECT SUBJECT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              value: _selectedSubject,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                              items: _teacherSubjects.map((subject) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: subject,
                                  child: Text('${subject['code']} — ${subject['name']}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedSubject = value;
                                  });
                                  _fetchStudentsForSubject(value);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Date Picker
                        Text(
                          'DATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Icon(Icons.calendar_today, size: 20, color: colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Student List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student Roster',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_allStudents.length} Students',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_allStudents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text("No students found for this subject's semester.")),
                    )
                  else
                    ..._allStudents.map((student) => _buildStudentRow(context, student)),
                ],
              ),
            ),

            // Bottom Fixed Actions
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -8),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                ),
                                Text(
                                  '$markedCount/${_allStudents.length} Marked',
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle), margin: const EdgeInsets.only(right: 4)),
                                    Text('$presentCount PRES', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.error, shape: BoxShape.circle), margin: const EdgeInsets.only(right: 4)),
                                    Text('$absentCount ABS', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ElevatedButton.icon(
                          icon: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Icon(Icons.cloud_upload_outlined),
                          label: Text(_isSaving ? 'SAVING...' : 'SUBMIT ATTENDANCE'),
                          onPressed: (_isSaving || _allStudents.isEmpty) ? null : _submitAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentRow(BuildContext context, _Student student) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnmarked = student.isPresent == null;
    final isPresent = student.isPresent == true;
    final isAbsent = student.isPresent == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUnmarked ? Border(left: BorderSide(color: colorScheme.primary, width: 4)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: student.avatarColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: student.avatarColor.withOpacity(0.4), width: 4),
                ),
                alignment: Alignment.center,
                child: Text(
                  student.initials,
                  style: TextStyle(
                    color: student.onAvatarColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    student.studentCode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => student.isPresent = true);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPresent ? Colors.teal[600] : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isPresent
                        ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 4)]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'P',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isPresent ? Colors.white : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() => student.isPresent = false);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAbsent ? colorScheme.error : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isAbsent
                        ? [BoxShadow(color: colorScheme.error.withOpacity(0.3), blurRadius: 4)]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isAbsent ? Colors.white : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
