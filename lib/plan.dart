import 'package:flutter/material.dart';
import 'package:admin_app/main.dart'; // Contains Supabase client

class InsertSubscriptionPlanPage extends StatefulWidget {
  const InsertSubscriptionPlanPage({super.key});

  @override
  _InsertSubscriptionPlanPageState createState() =>
      _InsertSubscriptionPlanPageState();
}

class _InsertSubscriptionPlanPageState
    extends State<InsertSubscriptionPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _durationController = TextEditingController();
  final _amountController = TextEditingController();
  List<Map<String, dynamic>> planData = [];
  bool _isLoading = false;
  bool _isFormVisible = false;
  int? _editingId;

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _durationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> fetchPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('tbl_plan')
          .select()
          .order('plan_name', ascending: true);

      setState(() {
        planData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching subscription plans: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch subscription plans')),
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
        // Insert new plan
        await supabase.from('tbl_plan').insert({
          'plan_name': _planNameController.text,
          'plan_duration': int.parse(_durationController.text),
          'plan_amount': double.parse(_amountController.text),
        });
      } else {
        // Update existing plan
        await supabase.from('tbl_subscription_plan').update({
          'plan_name': _planNameController.text,
          'plan_duration': int.parse(_durationController.text),
          'plan_amount': double.parse(_amountController.text),
        }).eq('id', _editingId!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingId == null
              ? 'Plan added successfully'
              : 'Plan updated successfully'),
        ),
      );
      setState(() {
        _planNameController.clear();
        _durationController.clear();
        _amountController.clear();
        _editingId = null;
        _isFormVisible = false;
      });
      fetchPlans();
    } catch (e) {
      print("Error inserting/updating plan: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to insert/update plan')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deletePlan(int id, String planName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this subscription plan? This action cannot be undone.'),
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
      await supabase.from('tbl_subscription_plan').delete().eq('id', id);

      fetchPlans();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan deleted successfully')),
      );
    } catch (e) {
      print("Error deleting plan: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete plan')),
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
                'Manage Subscription Plans',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: Icon(_isFormVisible ? Icons.close : Icons.add),
                label: Text(_isFormVisible ? 'Close' : 'Add Plan'),
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible;
                    if (!_isFormVisible) {
                      _planNameController.clear();
                      _durationController.clear();
                      _amountController.clear();
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
                              _editingId == null ? 'Add New Plan' : 'Edit Plan',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _planNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Plan Name',
                                      border: OutlineInputBorder(),
                                      hintText: 'Enter plan name',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a plan name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _durationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Duration (days)',
                                      border: OutlineInputBorder(),
                                      hintText: 'Enter duration in days',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter duration';
                                      }
                                      if (int.tryParse(value) == null ||
                                          int.parse(value) <= 0) {
                                        return 'Please enter a valid positive number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountController,
                                    decoration: const InputDecoration(
                                      labelText: 'Amount',
                                      border: OutlineInputBorder(),
                                      hintText: 'Enter amount',
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter amount';
                                      }
                                      if (double.tryParse(value) == null ||
                                          double.parse(value) < 0) {
                                        return 'Please enter a valid non-negative amount';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
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
                                          ? 'Add Plan'
                                          : 'Update Plan'),
                                ),
                                if (_editingId != null) ...[
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _editingId = null;
                                        _planNameController.clear();
                                        _durationController.clear();
                                        _amountController.clear();
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
                'Existing Plans',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                onPressed: fetchPlans,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : planData.isEmpty
                    ? const Center(child: Text('No plans found'))
                    : Card(
                        elevation: 2,
                        child: ListView.separated(
                          itemCount: planData.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final plan = planData[index];
                            return ListTile(
                              title: Text(plan['plan_name'] ?? 'Unnamed Plan'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Duration: ${plan['plan_duration']} days'),
                                  Text(
                                      'Amount: \$${plan['plan_amount'].toStringAsFixed(2)}'),
                                  if (plan['created_at'] != null)
                                    Text(
                                        'Created: ${DateTime.parse(plan['created_at']).toLocal().toString().split('.')[0]}'),
                                  if (plan['updated_at'] != null)
                                    Text(
                                        'Updated: ${DateTime.parse(plan['updated_at']).toLocal().toString().split('.')[0]}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      setState(() {
                                        _planNameController.text =
                                            plan['plan_name'] ?? '';
                                        _durationController.text =
                                            plan['duration'].toString();
                                        _amountController.text =
                                            plan['amount'].toString();
                                        _editingId = plan['id'];
                                        _isFormVisible = true;
                                      });
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => deletePlan(
                                        plan['id'], plan['plan_name']),
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
