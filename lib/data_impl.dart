import 'package:readlog/utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'data.dart';

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

class _BookReadHistoryMapper {
  static final idColumn = "id";
  static final bookIdColumn = "book_id";
  static final dateTimeFromColumn = "date_time_from";
  static final dateTimeToColumn = "date_time_to";
  static final pageFromColumn = "page_from";
  static final pageToColumn = "page_to";

  static Map<String, Object?> toMap(BookReadHistoryEntity entity) =>
      <String, Object?>{
        idColumn: entity.id,
        bookIdColumn: entity.bookId,
        dateTimeFromColumn: entity.dateTimeFrom.toUnixSeconds(),
        dateTimeToColumn: entity.dateTimeTo.toUnixSeconds(),
        pageFromColumn: entity.pageFrom,
        pageToColumn: entity.pageTo
      };

  static BookReadHistoryEntity fromMap(Map<String, Object?> map) =>
      BookReadHistoryEntity(
        id: map[idColumn] as int?,
        bookId: map[bookIdColumn] as int,
        dateTimeFrom: (map[dateTimeFromColumn] as int).unixSecondsToDateTime(),
        dateTimeTo: (map[dateTimeToColumn] as int).unixSecondsToDateTime(),
        pageFrom: map[pageFromColumn] as int,
        pageTo: map[pageToColumn] as int,
      );
}

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

final bookTable = "books";
final bookDetailsTable = "book_details";
final readHistoryTable = "read_histories";
final readRangesTable = "book_read_ranges";
final collectionsTable = "collections";

class BookDataSource implements BookRepository {
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
    return await _db.transaction((txn) async {
      int id = await txn.insert(bookTable, _BookMapper.toMap(book),
          conflictAlgorithm: ConflictAlgorithm.fail);

      for (final collection in book.collections) {
        await _insertCollectionBook(
            txn, id, collection.id!, ConflictAlgorithm.fail);
      }

      return id;
    });
  }

  @override
  Future<void> update(BookDetailEntity book) async {
    await _db.transaction((txn) async {
      await txn.update(bookTable, _BookMapper.toMap(book),
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
  }

  @override
  Future<List<BookEntity>> getAll() async {
    var rows = await _db.query(bookDetailsTable);
    return rows.map(_BookMapper.fromMap).toList();
  }

  @override
  Future<BookDetailEntity?> getById(int id) async {
    var rows =
        await _db.query(bookDetailsTable, where: "id = ?", whereArgs: [id]);
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
    await _db.delete(bookTable, where: "id = ?", whereArgs: [id]);
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

class BookReadHistoryDataSource implements BookReadHistoryRepository {
  Database database;

  BookReadHistoryDataSource(this.database);

  @override
  Future<int> add(BookReadHistoryEntity history) async {
    return await database.insert(
        readHistoryTable, _BookReadHistoryMapper.toMap(history),
        conflictAlgorithm: ConflictAlgorithm.fail);
  }

  @override
  Future<void> update(BookReadHistoryEntity history) async {
    await database.update(
      readHistoryTable,
      _BookReadHistoryMapper.toMap(history),
      where: "id = ?",
      whereArgs: [history.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await database.delete(readHistoryTable, where: "id = ?", whereArgs: [id]);
  }

  @override
  Future<List<BookReadHistoryEntity>> getAllByBook(int bookId) async {
    final list = await database.query(readHistoryTable,
        where: "book_id = ?",
        whereArgs: [bookId],
        orderBy: "date_time_from DESC");
    return list.map(_BookReadHistoryMapper.fromMap).toList();
  }

  @override
  Future<BookReadHistoryEntity?> getLastByBook(int bookId) async {
    final row = await database.query(readHistoryTable,
        where: "book_id = ?",
        whereArgs: [bookId],
        limit: 1,
        orderBy: "date_time_to DESC");
    if (row.isEmpty) return null;
    return _BookReadHistoryMapper.fromMap(row.first);
  }

  @override
  Future<List<BookReadRangeEntity>> getAllMergedByBook(int bookId) async {
    final rows = await database
        .query(readRangesTable, where: "book_id = ?", whereArgs: [bookId]);
    return rows
        .map((map) => BookReadRangeEntity(
            pageFrom: map["page_from"] as int, pageTo: map["page_to"] as int))
        .toList();
  }

  @override
  Future<BookReadStatistic> getStatistic(
      DateTime fromDay, DateTime toDay) async {
    var fromTime = fromDay.toDateOnly().toUnixSeconds(); // inclusive
    var toTime =
        toDay.toDateOnly().add(Duration(days: 1)).toUnixSeconds(); // exclusive

    final rows = await database.rawQuery("""
SELECT 
  SUM(MIN(date_time_to, ?) - MAX(date_time_from, ?)) AS seconds,
  SUM(page_to - page_from + 1) AS pages,
  COUNT(DISTINCT book_id) AS books
FROM read_histories
WHERE 
  (date_time_from >= ? AND date_time_from < ?) OR
  (date_time_to >= ? AND date_time_to < ?)
""", [toTime, fromTime, fromTime, toTime, fromTime, toTime]);
    int seconds = 0;
    int pages = 0;
    int books = 0;
    if (rows.isNotEmpty) {
      seconds = rows.first["seconds"] as int? ?? 0;
      pages = rows.first["pages"] as int? ?? 0;
      books = rows.first["books"] as int? ?? 0;
    }

    return BookReadStatistic(
      seconds: seconds,
      pages: pages,
      books: books,
    );
  }
}

class CollectionDataSource implements CollectionRepository {
  Database database;

  CollectionDataSource(this.database);

  @override
  Future<int> add(CollectionEntity collection) async {
    return await database.insert(
        collectionsTable, _CollectionMapper.toMap(collection));
  }

  @override
  Future<void> delete(int id) async {
    await database.delete(collectionsTable, where: "id = ?", whereArgs: [id]);
  }

  @override
  Future<List<CollectionEntity>> getAll() async {
    final rows = await database.query(collectionsTable);
    return rows.map(_CollectionMapper.fromMap).toList();
  }

  @override
  Future<void> update(CollectionEntity collection) async {
    await database.update(
      collectionsTable,
      _CollectionMapper.toMap(collection),
      where: "id = ?",
      whereArgs: [collection.id],
    );
  }

  @override
  Future<CollectionEntity?> getById(int id) async {
    final rows = await database.query(
      collectionsTable,
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _CollectionMapper.fromMap(rows.first);
  }
}

class RepositoryProviderImpl implements RepositoryProvider {
  late Database db;
  late BookDataSource bookDataSource;
  late BookReadHistoryDataSource bookReadHistoryDataSource;
  late CollectionDataSource collectionDataSource;

  Future<void> open() async {
    final dbPath = join(await getDatabasesPath(), "db");
    db = await openDatabase(dbPath, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute("""
CREATE TABLE IF NOT EXISTS books(
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  page_count INT NOT NULL
)""");
      await db.execute("""
CREATE TABLE IF NOT EXISTS read_histories(
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  date_time_from INTEGER NOT NULL,
  date_time_to INTEGER NOT NULL,
  page_from INTEGER NOT NULL,
  page_to INTEGER NOT NULL,
  FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE ON UPDATE CASCADE    
)""");
      await db.execute("""
CREATE INDEX read_histories_ranges
ON read_histories(book_id, page_from, page_to)
""");
      await db.execute("""
CREATE VIEW IF NOT EXISTS book_read_ranges AS
WITH RECURSIVE merged AS (
  SELECT 
  	id,
  	book_id,
  	page_from,
  	page_to
  FROM read_histories
  WHERE id = (
  	SELECT id
    FROM read_histories h WHERE h.book_id = read_histories.book_id
 		ORDER BY h.page_from, h.page_to
    LIMIT 1
  )
  UNION ALL
  SELECT 
  	read_histories.id,
  	read_histories.book_id,
  	MAX(merged.page_to + 1, read_histories.page_from) AS page_from,
  	read_histories.page_to as page_to
  FROM read_histories, merged
  WHERE read_histories.id = (
    SELECT id
    FROM read_histories h WHERE h.book_id = merged.book_id AND h.page_to > merged.page_to
    ORDER BY h.page_from, h.page_to
    LIMIT 1
  )
)
SELECT * FROM merged
""");
      await db.execute("""
CREATE VIEW IF NOT EXISTS book_readed_counts AS
WITH RECURSIVE merged AS (
  SELECT 
  	id,
  	book_id,
  	page_from,
  	page_to
  FROM read_histories
  WHERE id = (
  	SELECT id
    FROM read_histories h WHERE h.book_id = read_histories.book_id
 		ORDER BY h.page_from, h.page_to
    LIMIT 1
  )
  UNION ALL
  SELECT 
  	read_histories.id,
  	read_histories.book_id,
  	MAX(merged.page_to + 1, read_histories.page_from) AS page_from,
  	read_histories.page_to as page_to
  FROM read_histories, merged
  WHERE read_histories.id = (
    SELECT id
    FROM read_histories h WHERE h.book_id = merged.book_id AND h.page_to > merged.page_to
    ORDER BY h.page_from, h.page_to
    LIMIT 1
  )
)
SELECT 
	book_id,
  SUM(page_to - page_from + 1) as readed_page_count
FROM merged 
GROUP BY book_id
""");
      await db.execute("""
CREATE VIEW IF NOT EXISTS book_details AS   
SELECT 
  id,
  title,
  page_count,
  readed_page_count
FROM books
LEFT JOIN book_readed_counts
  ON book_readed_counts.book_id = books.id   
""");
    });
    await db.execute("""
CREATE TABLE IF NOT EXISTS collections(
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
)
""");
    await db.execute("""
CREATE TABLE IF NOT EXISTS collection_books(
  collection_id INTEGER NOT NULL,
  book_id INTEGER NOT NULL,
  FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (collection_id, book_id)
)
""");
    bookDataSource = BookDataSource(db);
    bookReadHistoryDataSource = BookReadHistoryDataSource(db);
    collectionDataSource = CollectionDataSource(db);
  }

  @override
  BookRepository get books => bookDataSource;

  @override
  BookReadHistoryRepository get readHistories => bookReadHistoryDataSource;

  @override
  CollectionRepository get collections => collectionDataSource;
}
