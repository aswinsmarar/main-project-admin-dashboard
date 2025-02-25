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
  int? _editingId;
    List<Map<String, String>> mockSoftSkills = [
    { 'softskill_name': 'Communication'},
    { 'softskill_name': 'Teamwork'},
    { 'softskill_name': 'Problem-Solving'},
    { 'softskill_name': 'Adaptability'},
    { 'softskill_name': 'Leadership'},
    { 'softskill_name': 'Time Management'},
    { 'softskill_name': 'Creativity'},
    { 'softskill_name': 'Conflict Resolution'},
    { 'softskill_name': 'Critical Thinking'},
    { 'softskill_name': 'Work Ethic'},
    { 'softskill_name': 'Empathy'},
    { 'softskill_name': 'Patience'},
    { 'softskill_name': 'Collaboration'},
    { 'softskill_name': 'Decision-Making'},
    { 'softskill_name': 'Conflict Management'},
    { 'softskill_name': 'Resilience'},
    { 'softskill_name': 'Open-Mindedness'},
    { 'softskill_name': 'Interpersonal Skills'},
    { 'softskill_name': 'Negotiation'},
    { 'softskill_name': 'Time Efficiency'},
    { 'softskill_name': 'Self-Discipline'},
    { 'softskill_name': 'Stress Management'},
    { 'softskill_name': 'Accountability'},
    { 'softskill_name': 'Confidence'},
    { 'softskill_name': 'Motivation'},
    { 'softskill_name': 'Active Listening'},
    { 'softskill_name': 'Delegation'},
    { 'softskill_name': 'Public Speaking'},
    { 'softskill_name': 'Creativity'},
    { 'softskill_name': 'Innovation'},
    { 'softskill_name': 'Goal-Oriented'},
    { 'softskill_name': 'Mentoring'},
    { 'softskill_name': 'Time Awareness'},
    { 'softskill_name': 'Conflict Avoidance'},
    { 'softskill_name': 'Self-Motivation'},
    { 'softskill_name': 'Work-Life Balance'},
    { 'softskill_name': 'Project Management'},
    { 'softskill_name': 'Organizational Skills'},
    { 'softskill_name': 'Attention to Detail'},
    { 'softskill_name': 'Strategic Thinking'},
    { 'softskill_name': 'Adaptability to Change'},
    { 'softskill_name': 'Crisis Management'},
    { 'softskill_name': 'Public Relations'},
    { 'softskill_name': 'Visionary Thinking'},
    { 'softskill_name': 'Customer Focus'},
    { 'softskill_name': 'Mindfulness'},
    { 'softskill_name': 'Continuous Learning'},
    { 'softskill_name': 'Workplace Etiquette'},
    { 'softskill_name': 'Team Building'},
    { 'softskill_name': 'Stress Resilience'},
  ];

  @override
  void initState() {
    super.initState();
    fetchSoftSkills();
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
      if (_editingId == null) {
        await supabase
            .from('tbl_softskill')
            .insert(mockSoftSkills);
      } else {
        await supabase
            .from('tbl_softskill')
            .update({'softskill_name': _softSkillController.text}).eq(
                'id', _editingId!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_editingId == null
                ? 'Soft Skill inserted successfully'
                : 'Soft Skill updated successfully')),
      );
      _softSkillController.clear();
      _editingId = null;
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

  Future<void> deleteSoftSkill(int id) async {
    try {
      await supabase.from('tbl_softskill').delete().eq('id', id);
      fetchSoftSkills();
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
          const Text(
            'Insert Soft Skill',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _softSkillController,
                    decoration: const InputDecoration(
                      labelText: 'Soft Skill Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a soft skill name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_editingId == null
                          ? 'Insert Soft Skill'
                          : 'Update Soft Skill'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Existing Soft Skills',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : softSkillData.isEmpty
                    ? const Center(child: Text('No soft skills found'))
                    : ListView.builder(
                        itemCount: softSkillData.length,
                        itemBuilder: (context, index) {
                          final skill = softSkillData[index];
                          return Card(
                            child: ListTile(
                              title: Text(skill['softskill_name']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _softSkillController.text =
                                            skill['softskill_name'];
                                        _editingId = skill['id'];
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await deleteSoftSkill(skill['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _softSkillController.dispose();
    super.dispose();
  }
}
