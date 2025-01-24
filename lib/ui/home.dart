import 'package:flutter/material.dart';
import 'package:readlog/ui/books.dart';
import 'package:readlog/ui/collections.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _Destination {
  final int index;
  final NavigationDestination navigationDestination;
  final WidgetBuilder builder;

  const _Destination({
    required this.index,
    required this.navigationDestination,
    required this.builder,
  });
}

class _HomePage extends State<HomePage> {
  List<_Destination> _destinations = [];
  int _selected = 0;

  @override
  void initState() {
    _destinations = [
      _Destination(
        index: 0,
        navigationDestination: const NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: "Books",
        ),
        builder: (context) => BooksPage.create(context),
      ),
      _Destination(index: 1,
          navigationDestination: NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            label: "Collections",
            selectedIcon: Icon(Icons.collections_bookmark),
          ), builder: (context) => CollectionsPage.create()
      ),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: _destinations.map((destination) => destination.navigationDestination).toList(),
        selectedIndex: _selected,
        onDestinationSelected: (index) {
          setState(() {
            _selected = index;
          });
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: _destinations.map((destination) {
          return Offstage(
            offstage: destination.index != _selected,
            child: destination.builder(context),
          );
        }).toList(),
      ),
    );
  }
}
