import 'package:flutter/material.dart';

class ViewCompaniesPage extends StatelessWidget {
  const ViewCompaniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement company fetching logic
    final companies = [
      {'id': 1, 'name': 'Acme Corp', 'industry': 'Technology'},
      {'id': 2, 'name': 'Globex Corporation', 'industry': 'Manufacturing'},
      {'id': 3, 'name': 'Initech', 'industry': 'Finance'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'View Companies',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: companies.length,
              itemBuilder: (context, index) {
                final company = companies[index];
                return Card(
                  child: ListTile(
                    title: Text(company['name'] as String),
                    subtitle: Text(company['industry'] as String),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Implement company editing logic
                      },
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
}

