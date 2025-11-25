import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Misplace No More',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ItemListScreen(),
    );
  }
}

/// Model class representing an item that can be tracked
class TrackedItem {
  final String id;
  final String name;
  final String location;
  final DateTime dateAdded;
  bool isFound;

  TrackedItem({
    required this.id,
    required this.name,
    required this.location,
    required this.dateAdded,
    this.isFound = true,
  });
}

/// Main screen displaying the list of tracked items
class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final List<TrackedItem> _items = [];

  void _addItem(String name, String location) {
    setState(() {
      _items.add(TrackedItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        location: location,
        dateAdded: DateTime.now(),
      ));
    });
  }

  void _toggleItemStatus(String id) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index].isFound = !_items[index].isFound;
      }
    });
  }

  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Keys, Wallet, Phone',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Kitchen drawer, Desk',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  locationController.text.isNotEmpty) {
                _addItem(nameController.text, locationController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Misplace No More'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No items tracked yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add an item',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ItemCard(
                  item: item,
                  onToggleStatus: () => _toggleItemStatus(item.id),
                  onDelete: () => _deleteItem(item.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Card widget displaying a single tracked item
class ItemCard extends StatelessWidget {
  final TrackedItem item;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const ItemCard({
    super.key,
    required this.item,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          item.isFound ? Icons.check_circle : Icons.help_outline,
          color: item.isFound ? Colors.green : Colors.orange,
          size: 32,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isFound ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text(item.location)),
              ],
            ),
            Text(
              item.isFound ? 'Found' : 'Lost',
              style: TextStyle(
                color: item.isFound ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                item.isFound ? Icons.search_off : Icons.search,
                color: item.isFound ? Colors.orange : Colors.green,
              ),
              tooltip: item.isFound ? 'Mark as Lost' : 'Mark as Found',
              onPressed: onToggleStatus,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
