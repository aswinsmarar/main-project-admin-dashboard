import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';

class InsertTechnicalSkillPage extends StatefulWidget {
  const InsertTechnicalSkillPage({super.key});

  @override
  _InsertTechnicalSkillPageState createState() => _InsertTechnicalSkillPageState();
}

class _InsertTechnicalSkillPageState extends State<InsertTechnicalSkillPage> {
  final _formKey = GlobalKey<FormState>();
  final _skillController = TextEditingController();
  List<Map<String, dynamic>> skillData = [];
  bool _isLoading = false;
  int? _editingId;
  List<Map<String, String>> mockTechnicalSkills = [
    { 'technicalskill_name': 'Flutter'},
    { 'technicalskill_name': 'Dart'},
    { 'technicalskill_name': 'JavaScript'},
    { 'technicalskill_name': 'TypeScript'},
    { 'technicalskill_name': 'Python'},
    { 'technicalskill_name': 'Java'},
    { 'technicalskill_name': 'C++'},
    { 'technicalskill_name': 'C#'},
    { 'technicalskill_name': 'Swift'},
    { 'technicalskill_name': 'Kotlin'},
    { 'technicalskill_name': 'Go'},
    { 'technicalskill_name': 'Rust'},
    { 'technicalskill_name': 'SQL'},
    { 'technicalskill_name': 'NoSQL'},
    { 'technicalskill_name': 'MongoDB'},
    { 'technicalskill_name': 'PostgreSQL'},
    { 'technicalskill_name': 'Firebase'},
    { 'technicalskill_name': 'Supabase'},
    { 'technicalskill_name': 'GraphQL'},
    { 'technicalskill_name': 'REST API'},
    { 'technicalskill_name': 'Docker'},
    { 'technicalskill_name': 'Kubernetes'},
    { 'technicalskill_name': 'CI/CD'},
    { 'technicalskill_name': 'Git'},
    { 'technicalskill_name': 'GitHub'},
    { 'technicalskill_name': 'AWS'},
    { 'technicalskill_name': 'Google Cloud'},
    { 'technicalskill_name': 'Azure'},
    { 'technicalskill_name': 'Machine Learning'},
    { 'technicalskill_name': 'Deep Learning'},
    { 'technicalskill_name': 'TensorFlow'},
    { 'technicalskill_name': 'PyTorch'},
    { 'technicalskill_name': 'Computer Vision'},
    { 'technicalskill_name': 'NLP'},
    { 'technicalskill_name': 'Cybersecurity'},
    { 'technicalskill_name': 'Penetration Testing'},
    { 'technicalskill_name': 'Blockchain'},
    { 'technicalskill_name': 'Smart Contracts'},
    { 'technicalskill_name': 'React'},
    { 'technicalskill_name': 'Angular'},
    { 'technicalskill_name': 'Vue.js'},
    { 'technicalskill_name': 'Node.js'},
    { 'technicalskill_name': 'Express.js'},
    { 'technicalskill_name': 'Spring Boot'},
    { 'technicalskill_name': 'Django'},
    { 'technicalskill_name': 'Flask'},
    { 'technicalskill_name': 'ASP.NET'},
    { 'technicalskill_name': 'Data Structures'},
    { 'technicalskill_name': 'Algorithms'},
    { 'technicalskill_name': 'Software Architecture'},
  ];

  @override
  void initState() {
    super.initState();
    fetchTechnicalSkills();
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
      print("Error fetching skills: $e");
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
      if (_editingId == null) {
        await supabase.from('tbl_technicalskills').insert({'technicalskill_name': _skillController.text});
      } else {
        await supabase
            .from('tbl_technicalskills')
            .update({'technicalskill_name': _skillController.text})
            .eq('id', _editingId!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId == null ? 'Skill inserted successfully' : 'Skill updated successfully')),
      );
      _skillController.clear();
      _editingId = null;
      fetchTechnicalSkills();
    } catch (e) {
      print("Error inserting/updating skill: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to insert/update skill')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deleteSkill(int id) async {
    try {
      await supabase.from('tbl_technicalskills').delete().eq('id', id);
      fetchTechnicalSkills();
    } catch (e) {
      print("Error deleting skill: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete skill')),
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
            'Insert Technical Skill',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skillController,
                    decoration: const InputDecoration(
                      labelText: 'Technical Skill Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a technical skill name';
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
                      : Text(_editingId == null ? 'Insert Skill' : 'Update Skill'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Existing Technical Skills',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : skillData.isEmpty
                    ? const Center(child: Text('No technical skills found'))
                    : ListView.builder(
                        itemCount: skillData.length,
                        itemBuilder: (context, index) {
                          final skill = skillData[index];
                          return Card(
                            child: ListTile(
                              title: Text(skill['technicalskill_name']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _skillController.text = skill['technicalskill_name'];
                                        _editingId = skill['id'];
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await deleteSkill(skill['id']);
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
    _skillController.dispose();
    super.dispose();
  }
}
