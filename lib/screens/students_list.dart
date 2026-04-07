import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_student.dart';

class StudentsList extends StatefulWidget {
  const StudentsList({super.key});

  @override
  State<StudentsList> createState() => _StudentsListState();
}

class _StudentsListState extends State<StudentsList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  Map<String, double> _attendancePercentages = {};
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      // Fetch all students (role=student)
      final data = await Supabase.instance.client
          .from('users')
          .select('id, name, email, batch, semester, role, roll_number')
          .eq('role', 'student')
          .eq('is_admin', false);
          
      _allStudents = data.cast<Map<String, dynamic>>();

      // Fetch attendance for calculating overall percentage
      final attendanceData = await Supabase.instance.client
          .from('attendance')
          .select('student_id, status');

      // Calculate attendance per student
      Map<String, int> totalClasses = {};
      Map<String, int> presentClasses = {};
      
      for (var a in attendanceData) {
        String sId = a['student_id'];
        totalClasses[sId] = (totalClasses[sId] ?? 0) + 1;
        if (a['status'] == 'present') {
          presentClasses[sId] = (presentClasses[sId] ?? 0) + 1;
        }
      }

      for (var st in _allStudents) {
        String sId = st['id'];
        if (totalClasses.containsKey(sId) && totalClasses[sId]! > 0) {
          _attendancePercentages[sId] = (presentClasses[sId] ?? 0) / totalClasses[sId]!;
        } else {
          _attendancePercentages[sId] = 0.0;
        }
      }

      if (mounted) {
        setState(() {
          _filteredStudents = List.from(_allStudents);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading student data: $e')),
        );
      }
    }
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      setState(() => _filteredStudents = List.from(_allStudents));
    } else {
      setState(() {
        _filteredStudents = _allStudents.where((s) {
          final name = (s['name'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) return true;
        return false;
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Students List'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterStudents,
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredStudents.isEmpty
                ? const Center(child: Text('No students found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final sId = student['id'];
                      final percentage = _attendancePercentages[sId] ?? 0.0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  student['name'].toString().isNotEmpty ? student['name'].toString()[0].toUpperCase() : '?',
                                  style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['name'] ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if ((student['roll_number'] ?? '').toString().isNotEmpty)
                                      Text(
                                        'Roll: ${student['roll_number']}',
                                        style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    Text(
                                      student['email'] ?? 'No Email',
                                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${student['batch'] ?? "No Batch"} | Sem ${student['semester'] ?? '-'}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Attendance',
                                    style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                                  ),
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: percentage >= 0.75 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddStudent()),
            ).then((_) => _fetchStudents()); // Refresh list on return
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Add Student'),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
