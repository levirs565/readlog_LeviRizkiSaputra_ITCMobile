part of '../sqlite.dart';

class _CollectionMapper {
  static final idColumn = "id";
  static final nameColumn = "name";

  static Map<String, Object?> toMap(CollectionEntity entity) =>
      {idColumn: entity.id, nameColumn: entity.name};

  static CollectionEntity fromMap(Map<String, Object?> map) => CollectionEntity(
    id: map[idColumn] as int?,
    name: map[nameColumn] as String,
  );
}


class CollectionDataSource extends ChangeNotifier implements CollectionRepository {
  Database database;

  CollectionDataSource(this.database);

  @override
  Future<int> add(CollectionEntity collection) async {
    final res = await database.insert(
        _collectionsTable, _CollectionMapper.toMap(collection));
    notifyListeners();
    return res;
  }

  @override
  Future<void> delete(int id) async {
    await database.delete(_collectionsTable, where: "id = ?", whereArgs: [id]);
    notifyListeners();
  }

  @override
  Future<List<CollectionEntity>> getAll() async {
    final rows = await database.query(_collectionsTable);
    return rows.map(_CollectionMapper.fromMap).toList();
  }

  @override
  Future<void> update(CollectionEntity collection) async {
    await database.update(
      _collectionsTable,
      _CollectionMapper.toMap(collection),
      where: "id = ?",
      whereArgs: [collection.id],
    );
    notifyListeners();
  }

  @override
  Future<CollectionEntity?> getById(int id) async {
    final rows = await database.query(
      _collectionsTable,
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _CollectionMapper.fromMap(rows.first);
  }
}
