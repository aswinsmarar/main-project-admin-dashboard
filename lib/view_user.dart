import 'package:flutter/material.dart';

class ViewUsersPage extends StatelessWidget {
  const ViewUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement user fetching logic
    final users = [
      {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'},
      {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com'},
      {'id': 3, 'name': 'Bob Johnson', 'email': 'bob@example.com'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'View Users',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  child: ListTile(
                    title: Text(user['name'] as String),
                    subtitle: Text(user['email'] as String),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Implement user editing logic
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

