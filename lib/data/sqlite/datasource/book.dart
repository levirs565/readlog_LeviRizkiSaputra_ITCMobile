part of '../sqlite.dart';

class _BookMapper {
  static final idColumn = "id";
  static final titleColumn = "title";
  static final pageCountColumn = "page_count";
  static final readedPageCountColumn = "readed_page_count";

  static Map<String, Object?> toMap(BookEntity entity) => <String, Object?>{
    idColumn: entity.id,
    titleColumn: entity.title,
    pageCountColumn: entity.pageCount,
  };

  static BookEntity fromMap(Map<String, Object?> map) => BookEntity(
    id: map[idColumn] as int?,
    title: map[titleColumn] as String,
    pageCount: map[pageCountColumn] as int,
    readedPageCount: map[readedPageCountColumn] as int? ?? 0,
  );
}

class BookDataSource extends ChangeNotifier implements BookRepository {
  Database _db;

  BookDataSource(this._db);

  Future<void> _insertCollectionBook(
      Transaction txn,
      int bookId,
      int collectionId,
      ConflictAlgorithm onConflict,
      ) async {
    await txn.insert(
      "collection_books",
      {
        "book_id": bookId,
        "collection_id": collectionId,
      },
      conflictAlgorithm: onConflict,
    );
  }

  @override
  Future<int> add(BookDetailEntity book) async {
    final res = await _db.transaction((txn) async {
      int id = await txn.insert(_bookTable, _BookMapper.toMap(book),
          conflictAlgorithm: ConflictAlgorithm.fail);

      for (final collection in book.collections) {
        await _insertCollectionBook(
            txn, id, collection.id!, ConflictAlgorithm.fail);
      }
      return id;
    });
    notifyListeners();
    return res;
  }

  @override
  Future<void> update(BookDetailEntity book) async {
    await _db.transaction((txn) async {
      await txn.update(_bookTable, _BookMapper.toMap(book),
          where: "id = ?", whereArgs: [book.id]);

      final extraParams = book.collections.map((el) => "?").join(",");
      final params = [book.id, ...book.collections.map((el) => el.id)];

      await txn.rawQuery("""
DELETE FROM collection_books 
WHERE
  book_id = ? AND
  collection_id NOT IN ($extraParams)
""", params);

      for (final collection in book.collections) {
        await _insertCollectionBook(
            txn, book.id!, collection.id!, ConflictAlgorithm.ignore);
      }
    });
    notifyListeners();
  }

  @override
  Future<List<BookEntity>> getAll() async {
    var rows = await _db.query(_bookDetailsTable);
    return rows.map(_BookMapper.fromMap).toList();
  }

  @override
  Future<BookDetailEntity?> getById(int id) async {
    var rows =
    await _db.query(_bookDetailsTable, where: "id = ?", whereArgs: [id]);
    if (rows.isEmpty) return null;
    final book = _BookMapper.fromMap(rows.first);
    final collectionRows = await _db.rawQuery("""
SELECT *
FROM collection_books
JOIN collections ON collections.id = collection_books.collection_id
WHERE collection_books.book_id = ?
""", [id]);
    final collections = collectionRows.map(_CollectionMapper.fromMap).toList();
    return BookDetailEntity(
      book: book,
      collections: collections,
    );
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete(_bookTable, where: "id = ?", whereArgs: [id]);
    notifyListeners();
  }

  @override
  Future<List<BookEntity>> getAllByCollection(int collectionId) async {
    final rows = await _db.rawQuery("""
SELECT
  *
FROM collection_books
JOIN book_details ON collection_books.book_id = book_details.id
WHERE collection_books.collection_id = ?
""", [collectionId]);
    return rows.map(_BookMapper.fromMap).toList();
  }
}