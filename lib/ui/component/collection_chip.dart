import 'package:flutter/material.dart';
import 'package:readlog/data/entities.dart';

class CollectionChipList extends StatelessWidget {
  final List<CollectionEntity> items;
  final void Function(CollectionEntity item)? onSelect;

  const CollectionChipList({super.key, required this.items, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 4,
      spacing: 8,
      children: items.map((element) {
        return RawChip(
          label: Text(element.name),
          onPressed: () {
            onSelect?.call(element);
          },
        );
      }).toList(),
    );
  }
}

class CollectionChipInput extends StatelessWidget {
  final List<CollectionEntity> items;
  final InputDecoration decoration;
  final void Function()? onTap;

  const CollectionChipInput(
      {super.key, required this.items, required this.decoration, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: decoration,
        isEmpty: items.isEmpty,
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: items.map((collection) {
            return Chip(label: Text(collection.name));
          }).toList(),
        ),
      ),
    );
  }
}
