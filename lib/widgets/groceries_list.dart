import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';

import '../widgets/new_item_screen.dart';

class GroceriesList extends StatefulWidget {
  const GroceriesList({Key? key}) : super(key: key);

  @override
  State<GroceriesList> createState() => _GroceriesListState();
}

class _GroceriesListState extends State<GroceriesList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;

  String _error = '';

  addItems() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (ctx) => const NewItemScreen()));
    if (newItem != null) {
      setState(() {
        _groceryItems.add(newItem);
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('shoppinglistflutterapp-default-rtdb.firebaseio.com',
        'shopping-list.json');
    final response = await http.get(url);
    print(response.body);
    if(response.statusCode >=400) {
      setState(() {
        _error = "Failed to fetch data. Please try again later";
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> _loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      _loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    setState(() {
      _groceryItems = _loadedItems;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No item added yet.!'),
    );
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_groceryItems.isNotEmpty && !_isLoading) {
      content = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) => Dismissible(
                key: ValueKey(_groceryItems[index].id),
                direction: DismissDirection.endToStart,
                child: ListTile(
                  title: Text(_groceryItems[index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: _groceryItems[index].category.color,
                  ),
                  trailing: Text(_groceryItems[index].quantity.toString()),
                ),
                onDismissed: (direction) {
                  removeItem(_groceryItems[index]);
                },
              ));
    }

    if(_error.isNotEmpty) {
      content = Center(child: Text(_error),);
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text("Shopping List"),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => {addItems()},
            )
          ],
        ),
        body: content,
    );
  }

  void removeItem(GroceryItem groceryItem) {
    final url = Uri.https('shoppinglistflutterapp-default-rtdb.firebaseio.com',
        'shopping-list/${groceryItem.id}.json');
    final response = http.delete(url);
    _isLoading = false;
    setState(() {
      _groceryItems.remove(groceryItem);
    });
  }
}
