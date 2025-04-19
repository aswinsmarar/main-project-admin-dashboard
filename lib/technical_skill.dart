import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';

class InsertTechnicalSkillPage extends StatefulWidget {
  const InsertTechnicalSkillPage({super.key});

  @override
  _InsertTechnicalSkillPageState createState() =>
      _InsertTechnicalSkillPageState();
}

class _InsertTechnicalSkillPageState extends State<InsertTechnicalSkillPage> {
  final _formKey = GlobalKey<FormState>();
  final _skillController = TextEditingController();
  List<Map<String, dynamic>> skillData = [];
  bool _isLoading = false;
  bool _isFormVisible = false; // Controls form visibility
  int? _editingId;

  @override
  void initState() {
    super.initState();
    fetchTechnicalSkills();
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  Future<void> fetchTechnicalSkills() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('tbl_technicalskills')
          .select()
          .order('technicalskill_name', ascending: true);

      setState(() {
        skillData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching technical skills: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch technical skills')),
      );
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final timestamp = DateTime.now().toIso8601String();

      if (_editingId == null) {
        // Insert new technical skill
        await supabase.from('tbl_technicalskills').insert({
          'technicalskill_name': _skillController.text,
          'created_at': timestamp,
        });

        // Log activity
        try {
          await supabase.from('tbl_activity_log').insert({
            'action': 'New Technical Skill Added: ${_skillController.text}',
            'type': 'skill_create',
            'created_at': timestamp,
          });
        } catch (e) {
          print("Error logging activity: $e");
        }
      } else {
        // Update existing technical skill
        await supabase.from('tbl_technicalskills').update({
          'technicalskill_name': _skillController.text,
          'updated_at': timestamp,
        }).eq('id', _editingId!);

        // Log activity
        try {
          await supabase.from('tbl_activity_log').insert({
            'action': 'Technical Skill Updated: ${_skillController.text}',
            'type': 'skill_update',
            'created_at': timestamp,
          });
        } catch (e) {
          print("Error logging activity: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingId == null
              ? 'Technical Skill added successfully'
              : 'Technical Skill updated successfully'),
        ),
      );
      setState(() {
        _skillController.clear();
        _editingId = null;
        _isFormVisible = false; // Hide form after submission
      });
      fetchTechnicalSkills();
    } catch (e) {
      print("Error inserting/updating technical skill: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to insert/update technical skill')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deleteSkill(int id, String skillName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this technical skill? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase.from('tbl_technicalskills').delete().eq('id', id);

      // Log activity
      try {
        await supabase.from('tbl_activity_log').insert({
          'action': 'Technical Skill Deleted: $skillName',
          'type': 'skill_delete',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print("Error logging activity: $e");
      }

      fetchTechnicalSkills();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Technical Skill deleted successfully')),
      );
    } catch (e) {
      print("Error deleting technical skill: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete technical skill')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Technical Skills',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              ElevatedButton.icon(
                icon: Icon(_isFormVisible ? Icons.close : Icons.add, size: 20),
                label: Text(_isFormVisible ? 'Close' : 'Add Technical Skill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible;
                    if (!_isFormVisible) {
                      _skillController.clear();
                      _editingId = null;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isFormVisible ? null : 0,
            child: _isFormVisible
                ? Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _editingId == null
                                  ? 'Add New Technical Skill'
                                  : 'Edit Technical Skill',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _skillController,
                                    decoration: InputDecoration(
                                      labelText: 'Technical Skill Name',
                                      hintText: 'Enter technical skill name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Colors.blue),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a technical skill name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(_editingId == null
                                          ? 'Add Technical Skill'
                                          : 'Update Technical Skill'),
                                ),
                                if (_editingId != null) ...[
                                  const SizedBox(width: 12),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _editingId = null;
                                        _skillController.clear();
                                        _isFormVisible = false;
                                      });
                                    },
                                    child: const Text(
                                      'Cancel Edit',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Existing Technical Skills',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: fetchTechnicalSkills,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : skillData.isEmpty
                    ? const Center(child: Text('No technical skills found'))
                    : Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListView.separated(
                          itemCount: skillData.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final skill = skillData[index];
                            return ListTile(
                              title: Text(
                                skill['technicalskill_name'] ?? 'Unnamed',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              // subtitle: Column(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: [
                              //     if (skill['created_at'] != null)
                              //       Text(
                              //         'Created: ${DateTime.parse(skill['created_at']).toLocal().toString().split('.')[0]}',
                              //         style: TextStyle(
                              //             color: Colors.grey.shade600,
                              //             fontSize: 12),
                              //       ),
                              //     if (skill['updated_at'] != null)
                              //       Text(
                              //         'Updated: ${DateTime.parse(skill['updated_at']).toLocal().toString().split('.')[0]}',
                              //         style: TextStyle(
                              //             color: Colors.grey.shade600,
                              //             fontSize: 12),
                              //       ),
                              //   ],
                              // ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _skillController.text =
                                            skill['technicalskill_name'] ?? '';
                                        _editingId = skill['id'];
                                        _isFormVisible = true;
                                      });
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                    onPressed: () async {
                                      await deleteSkill(skill['id'],
                                          skill['technicalskill_name']);
                                    },
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
