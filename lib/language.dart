import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';

class InsertLanguagePage extends StatefulWidget {
  const InsertLanguagePage({super.key});

  @override
  _InsertLanguagePageState createState() => _InsertLanguagePageState();
}

class _InsertLanguagePageState extends State<InsertLanguagePage> {
  final _formKey = GlobalKey<FormState>();
  final _languageController = TextEditingController();
  List<Map<String, dynamic>> languageData = [];
  bool _isLoading = false;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    fetchLanguages();
  }

  Future<void> fetchLanguages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('tbl_language')
          .select()
          .order('language_name', ascending: true);
      
      setState(() {
        languageData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching languages: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch languages')),
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
        await supabase.from('tbl_language').insert({'language_name': _languageController.text});
      } else {
        await supabase
            .from('tbl_language')
            .update({'language_name': _languageController.text})
            .eq('id', _editingId!);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId == null ? 'Language inserted successfully' : 'Language updated successfully')),
      );
      _languageController.clear();
      _editingId = null;
      fetchLanguages();
    } catch (e) {
      print("Error inserting/updating language: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to insert/update language')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deleteLanguage(int id) async {
    try {
      await supabase.from('tbl_language').delete().eq('id', id);
      fetchLanguages();
    } catch (e) {
      print("Error deleting language: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete language')),
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
            'Insert Language',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _languageController,
                    decoration: const InputDecoration(
                      labelText: 'Language Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a language name';
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
                      : Text(_editingId == null ? 'Insert Language' : 'Update Language'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Existing Languages',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : languageData.isEmpty
                    ? const Center(child: Text('No languages found'))
                    : ListView.builder(
                        itemCount: languageData.length,
                        itemBuilder: (context, index) {
                          final language = languageData[index];
                          return Card(
                            child: ListTile(
                              title: Text(language['language_name']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _languageController.text = language['language_name'];
                                        _editingId = language['id'];
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await deleteLanguage(language['id']);
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
    _languageController.dispose();
    super.dispose();
  }
}
