import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';

class InsertSoftSkillPage extends StatefulWidget {
  const InsertSoftSkillPage({super.key});

  @override
  _InsertSoftSkillPageState createState() => _InsertSoftSkillPageState();
}

class _InsertSoftSkillPageState extends State<InsertSoftSkillPage> {
  final _formKey = GlobalKey<FormState>();
  final _softSkillController = TextEditingController();
  List<Map<String, dynamic>> softSkillData = [];
  bool _isLoading = false;
  bool _isFormVisible = false; // Controls form visibility
  int? _editingId;

  @override
  void initState() {
    super.initState();
    fetchSoftSkills();
  }

  @override
  void dispose() {
    _softSkillController.dispose();
    super.dispose();
  }

  Future<void> fetchSoftSkills() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('tbl_softskill')
          .select()
          .order('softskill_name', ascending: true);

      setState(() {
        softSkillData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching soft skills: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch soft skills')),
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
        // Insert new soft skill
        await supabase.from('tbl_softskill').insert({
          'softskill_name': _softSkillController.text,
          'created_at': timestamp,
        });

        // Log activity
        try {
          await supabase.from('tbl_activity_log').insert({
            'action': 'New Soft Skill Added: ${_softSkillController.text}',
            'type': 'skill_create',
            'created_at': timestamp,
          });
        } catch (e) {
          print("Error logging activity: $e");
        }
      } else {
        // Update existing soft skill
        await supabase.from('tbl_softskill').update({
          'softskill_name': _softSkillController.text,
          'updated_at': timestamp,
        }).eq('id', _editingId!);

        // Log activity
        try {
          await supabase.from('tbl_activity_log').insert({
            'action': 'Soft Skill Updated: ${_softSkillController.text}',
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
              ? 'Soft Skill added successfully'
              : 'Soft Skill updated successfully'),
        ),
      );
      setState(() {
        _softSkillController.clear();
        _editingId = null;
        _isFormVisible = false; // Hide form after submission
      });
      fetchSoftSkills();
    } catch (e) {
      print("Error inserting/updating soft skill: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to insert/update soft skill')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deleteSoftSkill(int id, String skillName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this soft skill? This action cannot be undone.'),
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
      await supabase.from('tbl_softskill').delete().eq('id', id);

      // Log activity
      try {
        await supabase.from('tbl_activity_log').insert({
          'action': 'Soft Skill Deleted: $skillName',
          'type': 'skill_delete',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print("Error logging activity: $e");
      }

      fetchSoftSkills();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soft Skill deleted successfully')),
      );
    } catch (e) {
      print("Error deleting soft skill: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete soft skill')),
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
                'Manage Soft Skills',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              ElevatedButton.icon(
                icon: Icon(_isFormVisible ? Icons.close : Icons.add, size: 20),
                label: Text(_isFormVisible ? 'Close' : 'Add Soft Skill'),
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
                      _softSkillController.clear();
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
                                  ? 'Add New Soft Skill'
                                  : 'Edit Soft Skill',
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
                                    controller: _softSkillController,
                                    decoration: InputDecoration(
                                      labelText: 'Soft Skill Name',
                                      hintText: 'Enter soft skill name',
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
                                        return 'Please enter a soft skill name';
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
                                          ? 'Add Soft Skill'
                                          : 'Update Soft Skill'),
                                ),
                                if (_editingId != null) ...[
                                  const SizedBox(width: 12),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _editingId = null;
                                        _softSkillController.clear();
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
                'Existing Soft Skills',
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
                onPressed: fetchSoftSkills,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : softSkillData.isEmpty
                    ? const Center(child: Text('No soft skills found'))
                    : Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListView.separated(
                          itemCount: softSkillData.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final skill = softSkillData[index];
                            return ListTile(
                              title: Text(
                                skill['softskill_name'] ?? 'Unnamed',
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
                                        _softSkillController.text =
                                            skill['softskill_name'] ?? '';
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
                                      await deleteSoftSkill(
                                          skill['id'], skill['softskill_name']);
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
