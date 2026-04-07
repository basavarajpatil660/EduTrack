import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  
  int _totalStudents = 0;
  double _overallAttendance = 0.0;
  
  List<Map<String, dynamic>> _lowAttendanceStudents = [];
  List<Map<String, dynamic>> _topMarksStudents = [];

  @override
  void initState() {
    super.initState();
    _fetchReportsData();
  }

  Future<void> _fetchReportsData() async {
    try {
      // 1. Total Students
      final studentData = await Supabase.instance.client
          .from('users')
          .select('id, name, batch, semester')
          .eq('role', 'student');
      _totalStudents = studentData.length;

      // 2. Attendance Stats
      final attendanceData = await Supabase.instance.client
          .from('attendance')
          .select('student_id, status');
          
      int totalClasses = attendanceData.length;
      int totalPresent = attendanceData.where((a) => a['status'] == 'present').length;
      _overallAttendance = totalClasses > 0 ? (totalPresent / totalClasses) : 0.0;

      // Compute Individual Attendance
      Map<String, int> studentTotalClasses = {};
      Map<String, int> studentPresentClasses = {};
      
      for (var a in attendanceData) {
        String sId = a['student_id'];
        studentTotalClasses[sId] = (studentTotalClasses[sId] ?? 0) + 1;
        if (a['status'] == 'present') {
          studentPresentClasses[sId] = (studentPresentClasses[sId] ?? 0) + 1;
        }
      }

      _lowAttendanceStudents = [];
      for (var st in studentData) {
        String sId = st['id'];
        int classesCount = studentTotalClasses[sId] ?? 0;
        int presentCount = studentPresentClasses[sId] ?? 0;
        double perc = classesCount > 0 ? (presentCount / classesCount) : 0.0;
        
        if (perc < 0.75 && classesCount > 0) {
          _lowAttendanceStudents.add({
            'name': st['name'],
            'batch': st['batch'],
            'percentage': perc,
          });
        }
      }

      // 3. Top Marks Stats
      final marksData = await Supabase.instance.client
          .from('marks')
          .select('student_id, total');

      Map<String, int> studentTotalMarks = {};
      for (var m in marksData) {
        String sId = m['student_id'];
        studentTotalMarks[sId] = (studentTotalMarks[sId] ?? 0) + (m['total'] as int);
      }

      List<MapEntry<String, int>> sortedMarks = studentTotalMarks.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
        
      _topMarksStudents = [];
      for (int i = 0; i < sortedMarks.length && i < 5; i++) {
        var entry = sortedMarks[i];
        var st = studentData.firstWhere((s) => s['id'] == entry.key, orElse: () => {'name': 'Unknown', 'batch': ''});
        _topMarksStudents.add({
          'name': st['name'],
          'batch': st['batch'],
          'total': entry.value,
        });
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        appBar: AppBar(
          title: const Text('Reports'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Students',
                            '$_totalStudents',
                            Icons.group,
                            colorScheme.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Class Attendance',
                            '${(_overallAttendance * 100).toStringAsFixed(1)}%',
                            Icons.fact_check,
                            colorScheme.secondaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Low Attendance List
                    const Text('Below 75% Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    if (_lowAttendanceStudents.isEmpty)
                      const Text('Great! All students have above 75% attendance.')
                    else
                      ..._lowAttendanceStudents.map((st) => Card(
                        color: Colors.red[50],
                        child: ListTile(
                          title: Text(st['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(st['batch'] ?? ''),
                          trailing: Text(
                            '${(st['percentage'] * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      )),
                    
                    const SizedBox(height: 32),
                    
                    // Top Students
                    const Text('Top 5 Performers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),
                    if (_topMarksStudents.isEmpty)
                      const Text('No marks data available.')
                    else
                      ..._topMarksStudents.map((st) => Card(
                        color: Colors.blue[50],
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events, color: Colors.amber),
                          title: Text(st['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(st['batch'] ?? ''),
                          trailing: Text(
                            '${st['total']} pts',
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
