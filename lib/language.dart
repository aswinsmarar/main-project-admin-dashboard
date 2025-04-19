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
  bool _isFormVisible = false; // Controls form visibility
  int? _editingId;

  @override
  void initState() {
    super.initState();
    fetchLanguages();
  }

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
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
      final timestamp = DateTime.now().toIso8601String();

      if (_editingId == null) {
        // Insert new language
        await supabase.from('tbl_language').insert({
          'language_name': _languageController.text,
          'created_at': timestamp,
        });
      } else {
        // Update existing language
        await supabase.from('tbl_language').update({
          'language_name': _languageController.text,
          'updated_at': timestamp,
        }).eq('id', _editingId!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingId == null
              ? 'Language added successfully'
              : 'Language updated successfully'),
        ),
      );
      setState(() {
        _languageController.clear();
        _editingId = null;
        _isFormVisible = false; // Hide form after submission
      });
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

  Future<void> deleteLanguage(int id, String languageName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this language? This action cannot be undone.'),
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
      await supabase.from('tbl_language').delete().eq('id', id);

      fetchLanguages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Language deleted successfully')),
      );
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Languages',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: Icon(_isFormVisible ? Icons.close : Icons.add),
                label: Text(_isFormVisible ? 'Close' : 'Add Language'),
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible;
                    if (!_isFormVisible) {
                      _languageController.clear();
                      _editingId = null;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isFormVisible ? null : 0,
            child: _isFormVisible
                ? Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _editingId == null
                                  ? 'Add New Language'
                                  : 'Edit Language',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _languageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Language Name',
                                      border: OutlineInputBorder(),
                                      hintText: 'Enter language name',
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
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text(_editingId == null
                                          ? 'Add Language'
                                          : 'Update Language'),
                                ),
                                if (_editingId != null) ...[
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _editingId = null;
                                        _languageController.clear();
                                      });
                                    },
                                    child: const Text('Cancel Edit'),
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Existing Languages',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                onPressed: fetchLanguages,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : languageData.isEmpty
                    ? const Center(child: Text('No languages found'))
                    : Card(
                        elevation: 2,
                        child: ListView.separated(
                          itemCount: languageData.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final language = languageData[index];
                            return ListTile(
                              title:
                                  Text(language['language_name'] ?? 'Unnamed'),
                              // subtitle: Column(
                              //   crossAxisAlignment: CrossAxisAlignment.start,
                              //   children: [
                              //     if (language['created_at'] != null)
                              //       Text(
                              //           'Created: ${DateTime.parse(language['created_at']).toLocal().toString().split('.')[0]}'),
                              //     if (language['updated_at'] != null)
                              //       Text(
                              //           'Updated: ${DateTime.parse(language['updated_at']).toLocal().toString().split('.')[0]}'),
                              //   ],
                              // ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      setState(() {
                                        _languageController.text =
                                            language['language_name'] ?? '';
                                        _editingId = language['id'];
                                        _isFormVisible =
                                            true; // Show form for editing
                                      });
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => deleteLanguage(
                                        language['id'],
                                        language['language_name']),
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
